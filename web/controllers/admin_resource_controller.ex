defmodule ExAdmin.AdminResourceController do
  @moduledoc false
  use ExAdmin.Web, :controller
  import ExAdmin.Utils
  import ExAdmin.ParamsToAtoms
  import ExAdmin.Gettext
  alias ExAdmin.Authorization

  plug :set_theme
  plug :set_layout

  def action(%{private: %{phoenix_action: action}} = conn, _options) do
    conn = conn |> assign(:xhr, get_req_header(conn, "x-requested-with") == ["XMLHttpRequest"])
    resource = conn.params["resource"]
    conn = scrub_params(conn, resource, action)
    params = filter_params(conn.params)
    defn = get_registered_by_controller_route!(conn, resource)

    if !restricted_action?(action, defn) && authorized_action?(conn, action, defn) do
      conn
      |> assign(:defn, defn)
      |> load_resource(action, defn, params[:id])
      |> handle_plugs(action, defn)
      |> handle_before_filter(action, defn, params)
      |> handle_custom_actions(action, defn, params)
    else
      render_403 conn
    end
  end

  defp render_403(conn) do
    conn
    |> put_layout(false)
    |> put_status(403)
    |> render(ExAdmin.ErrorView, "403.html")
    |> halt
  end

  defp restricted_action?(:destroy, defn), do: restricted_action?(:delete, defn)
  defp restricted_action?(:create, defn), do: restricted_action?(:new, defn)
  defp restricted_action?(:update, defn), do: restricted_action?(:edit, defn)
  defp restricted_action?(action, defn) do
    if action in [:show, :edit, :update, :new, :destroy, :delete] do
      not action in defn.actions
    else
      false
    end
  end

  defp scrub_params(conn, required_key, action) when action in [:create, :update] do
    if conn.params[required_key] do
      Phoenix.Controller.scrub_params conn, required_key
    else
      conn
    end
  end
  defp scrub_params(conn, _required_key, _action), do: conn

  defp load_resource(conn, _action, defn, nil) do
    resource = defn.resource_model.__struct__
    assign(conn, :resource, resource)
  end
  defp load_resource(conn, action, defn, resource_id) do
    model = defn.__struct__
    query = model.run_query(repo, defn, action, resource_id)
    resource =
    Authorization.authorize_query(defn, conn, query, action, resource_id)
    |> ExAdmin.Query.execute_query(repo, action, resource_id)

    if resource == nil do
      raise Phoenix.Router.NoRouteError, conn: conn, router: __MODULE__
    end

    assign(conn, :resource, resource)
  end

  def handle_custom_actions({conn, params}, action, defn, _) do
    handle_custom_actions(conn, action, defn, params)
  end
  def handle_custom_actions(conn, :member, defn, params) do
    %{member_actions: member_actions} = defn
    action = String.to_atom params[:action]
    cond do
      member_action = Keyword.get(member_actions, action) ->
        member_action[:fun].(conn, params)
      true ->
        render_403 conn
    end
  end
  def handle_custom_actions(conn, :collection, defn, params) do
    %{collection_actions: collection_actions} = defn
    action = String.to_atom params[:action]
    cond do
      collection_action = Keyword.get(collection_actions, action) ->
        collection_action[:fun].(conn, params)
      true ->
        render_403 conn
    end
  end

  def handle_custom_actions(conn, action, defn, params) do
    apply(__MODULE__, action, [conn, defn, params])
  end

  def handle_before_filter(conn, action, defn, params) do
    _handle_before_filter(conn, action, defn, params, defn.controller_filters[:before_filter])
  end

  def _handle_before_filter(conn, action, defn, params, [{name, opts} | t]) do
    filter = cond do
      opts[:only] ->
        if action in opts[:only], do: true, else: false
      opts[:except] ->
        if not action in opts[:except], do: true, else: false
      true -> true
    end
    if filter do
      apply(defn.__struct__, name, [conn, params])
    else
      conn
    end
    |> _handle_before_filter(action, defn, params, t)
  end
  def _handle_before_filter(conn, _action, _defn, _params, _), do: conn

  def handle_after_filter(conn, action, defn, params, resource) do
    _handle_after_filter({conn, params, resource}, action, defn, defn.controller_filters[:after_filter])
  end

  def _handle_after_filter({conn, params, resource}, action, defn, [{name, opts} | t]) do
    filter = cond do
      opts[:only] ->
        if action in opts[:only], do: true, else: false
      opts[:except] ->
        if not action in opts[:except], do: true, else: false
      true -> true
    end
    if filter do
      case apply(defn.__struct__, name, [conn, params, resource, action]) do
        {_, _, _} = tuple -> tuple
        %Plug.Conn{} = conn -> {conn, params, resource}
        error ->
          raise ExAdmin.RuntimeError, message: (gettext "invalid after_filter return:") <> " #{inspect error}"
      end
    else
      {conn, params, resource}
    end
    |> _handle_after_filter(action, defn, t)
  end
  def _handle_after_filter(args, _action, _defn, _), do: args

  defp handle_plugs(conn, :nested, _defn), do: conn
  defp handle_plugs(conn, _action, defn) do
    case Application.get_env(:ex_admin, :plug, []) do
      list when is_list(list) -> list
      item -> [{item, []}]
    end
    |> Keyword.merge(defn.plugs)
    |> Enum.reduce(conn, fn({name, opts}, conn) ->
      apply(name, :call, [conn, opts])
    end)
    |> authorized?
  end

  defp authorized?(%{assigns: %{authorized: true}} = conn), do: conn
  defp authorized?(%{assigns: %{authorized: false}}) do
    throw :unauthorized
  end
  defp authorized?(conn), do: conn


  def index(conn, defn, params) do
    model = defn.__struct__

    page = case conn.assigns[:page] do
      nil ->
        id = params |> Map.to_list
        query = model.run_query(repo, defn, :index, id)
        Authorization.authorize_query(defn, conn, query, :index, id)
        |> ExAdmin.Query.execute_query(repo, :index, id)

      page ->
        page
    end
    scope_counts = model.run_query_counts repo, defn, :index, params |> Map.to_list

    {conn, _params, page} = handle_after_filter(conn, :index, defn, params, page)

    contents = if function_exported? model, :index_view, 3 do
      apply(model, :index_view, [conn, page, scope_counts])
    else
      ExAdmin.Index.default_index_view(conn, page, scope_counts)
    end

    assign(conn, :scope_counts, scope_counts)
    |> render("admin.html", html: contents, page: page,
      filters: (if false in defn.index_filters, do: false, else: defn.index_filters))
  end

  def show(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    {conn, _params, resource} = handle_after_filter(conn, :show, defn, params, resource)

    contents = if function_exported? model, :show_view, 2 do
      apply(model, :show_view, [conn, resource])
    else
      ExAdmin.Show.default_show_view(conn, resource)
    end

    render conn, "admin.html", html: contents, filters: nil
  end

  def edit(conn, defn, params) do
    resource = conn.assigns.resource
    conn = Plug.Conn.assign(conn, :ea_required,
       defn.resource_model.changeset(resource).required)
    {conn, params, resource} = handle_after_filter(conn, :edit, defn, params, resource)
    contents = do_form_view(conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
  end

  def new(conn, defn, params) do
    resource = conn.assigns.resource
    conn = Plug.Conn.assign(conn, :ea_required,
       defn.resource_model.changeset(resource).required)
    {conn, params, resource} = handle_after_filter(conn, :new, defn, params, resource)
    contents = do_form_view(conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
  end

  defp do_form_view(conn, resource, params) do
    model = conn.assigns.defn.__struct__
    if function_exported? model, :form_view, 3 do
      apply(model, :form_view, [conn, resource, params])
    else
      ExAdmin.Form.default_form_view conn, resource, params
    end
  end

  defp handle_changeset_error(conn, defn, changeset, params) do
    conn = put_flash(conn, :inline_error, changeset.errors)
    |> Plug.Conn.assign(:changeset, changeset)
    |> Plug.Conn.assign(:ea_required,
       defn.resource_model.changeset(conn.assigns.resource).required)
    contents = do_form_view(conn, ExAdmin.Changeset.get_data(changeset), params)
    render(conn, "admin.html", html: contents, filters: nil)
  end

  def create(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    changeset_fn = model.changeset_fn(defn, :create)
    changeset = ExAdmin.Repo.changeset(changeset_fn, resource, params[defn.resource_name])

    case ExAdmin.Repo.insert(changeset) do
      {:error, changeset} ->
        conn |> handle_changeset_error(defn, changeset, params)
      resource ->
        {conn, _, resource} = handle_after_filter(conn, :create, defn, params, resource)
        put_flash(conn, :notice, (gettext "%{model_name} was successfully created.", model_name: (base_name model) ))
        |> redirect(to: admin_resource_path(resource, :show))
    end
  end

  def update(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    changeset_fn = model.changeset_fn(defn, :update)
    changeset = ExAdmin.Repo.changeset(changeset_fn, resource, params[defn.resource_name])

    case ExAdmin.Repo.update(changeset) do
      {:error, changeset} ->
        conn |> handle_changeset_error(defn, changeset, params)
      resource ->
        {conn, _, resource} = handle_after_filter(conn, :update, defn, params, resource)
        put_flash(conn, :notice, "#{base_name model} " <> (gettext "was successfully updated."))
        |> redirect(to: admin_resource_path(resource, :show))
    end
  end

  def toggle_attr(conn, defn, %{attr_name: attr_name, attr_value: attr_value}) do
    resource = conn.assigns.resource
    attr_name_atom = String.to_existing_atom(attr_name)

    resource = resource
    |> defn.resource_model.changeset(%{attr_name => attr_value})
    |> repo.update!

    render conn, "toggle_attr.js", attr_name: attr_name, attr_value: Map.get(resource, attr_name_atom), id: ExAdmin.Schema.get_id(resource)
  end

  def destroy(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    ExAdmin.Repo.delete(resource, params[defn.resource_name])
    model_name = base_name model

    if conn.assigns.xhr do
      render conn, "destroy.js", tr_id: String.downcase("#{model_name}_#{params[:id]}")
    else
      put_flash(conn, :notice, "#{model_name} " <> (gettext "was successfully destroyed."))
      |> redirect(to: admin_resource_path(defn.resource_model, :index))
    end
  end

  def batch_action(conn, defn, %{batch_action: "destroy"} = params) do
    resource_model = defn.resource_model

    type = case ExAdmin.Schema.primary_key(resource_model) do
      nil -> :integer
      key -> resource_model.__schema__(:type, key)
    end

    ids = params[:collection_selection]
    count = Enum.count ids
    ids
    |> Enum.map(&(to_integer(type, &1)))
    |> Enum.each(fn(id) ->
      repo.delete repo.get(resource_model, id)
    end)

    put_flash(conn, :notice, "#{count} #{pluralize params[:resource], count} "
              <> (ngettext "was successfully destroyed.", "were successfully destroyed.", count))
    |> redirect(to: admin_resource_path(resource_model, :index))
  end

  defp to_integer(:id, string), do: string
  defp to_integer(:string, string), do: string
  defp to_integer(:integer, string) do
    case Integer.parse string do
      {int, ""} -> int
      _ -> string
    end
  end

  def csv(conn, defn, params) do
    model = defn.__struct__

    id = params |> Map.to_list
    query = model.run_query(repo, defn, :csv, id)
    csv = Authorization.authorize_query(defn, conn, query, :csv, id)
    |> ExAdmin.Query.execute_query(repo, :csv, id)
    |> case  do
      [] -> []
      resources ->
        if function_exported? model, :build_csv, 1 do
          model.build_csv(resources)
        else
          ExAdmin.CSV.build_csv(resources)
        end
    end

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("Content-Disposition", "inline; filename=\"#{params[:resource]}.csv\"")
    |> send_resp(conn.status || 200, csv)
  end

  @nested_key_list for i <- 1..5, do: {String.to_atom("nested#{i}"), String.to_atom("id#{i}")}

  def nested(conn, defn, params) do
    model = defn.__struct__

    resource = case conn.assigns.resource do
      [res] -> res
      other -> other
    end
    items = apply(model, :get_blocks, [conn, defn.resource_model.__struct__, params])
    block = deep_find(items, String.to_atom(params[:field_name]))

    resources = case block[:opts][:collection] do
      list when is_list(list) ->
        list
      fun when is_function(fun) ->
        fun.(conn, defn.resource_model.__struct__)
    end

    contents = apply(model, :ajax_view, [conn, params, resource, resources, block])

    send_resp(conn, conn.status || 200, "text/javascript", contents)
  end


  def deep_find(items, name) do
    Enum.reduce items, nil, fn(item, acc) ->
      case item do
        %{inputs: inputs} ->
          case Enum.find inputs, &(&1[:name] == name) do
            nil -> acc
            found -> found
          end
        _ -> acc
      end
    end
  end

  defp send_resp(conn, default_status, default_content_type, body) do
    conn
    |> ensure_resp_content_type(default_content_type)
    |> Plug.Conn.send_resp(conn.status || default_status, body)
  end

  defp ensure_resp_content_type(%{resp_headers: resp_headers} = conn, content_type) do
    if List.keyfind(resp_headers, "content-type", 0) do
      conn
    else
      content_type = content_type <> "; charset=utf-8"
      %{conn | resp_headers: [{"content-type", content_type}|resp_headers]}
    end
  end

  def repo, do: Application.get_env(:ex_admin, :repo)
end
