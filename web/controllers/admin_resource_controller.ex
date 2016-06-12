defmodule ExAdmin.AdminResourceController do
  @moduledoc false
  use ExAdmin.Web, :controller
  require Logger
  import ExAdmin.ParamsToAtoms
  import ExAdmin.Utils
  alias ExAdmin.Authorization

  plug :set_theme
  plug :set_layout

  def action(%{private: %{phoenix_action: action}} = conn, _options) do
    conn = conn |> assign(:xhr, get_req_header(conn, "x-requested-with") == ["XMLHttpRequest"])
    resource = conn.params["resource"]
    conn = scrub_params(conn, resource, action)
    params = filter_params(conn.params)
    defn = get_registered_by_controller_route!(conn, resource)

    # IO.puts ".... defn: #{defn.__struct__}, action: #{inspect action}"
    if authorized_action?(conn, action, defn) do
      conn
      |> assign(:defn, defn)
      |> load_resource(action, defn, params[:id])
      |> handle_plugs(action, defn)
      |> handle_before_filter(action, defn, params)
      |> handle_custom_actions(action, defn, params)
    else
      conn
      |> put_layout(false)
      |> render(ExAdmin.ErrorView, "403.html")
      |> halt
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
  def handle_custom_actions(conn, action, defn, params) do
    %{member_actions: member_actions, collection_actions: collection_actions} = defn
    cond do
      member_action = Keyword.get(member_actions, action) ->
        member_action.(conn, params)
      collection_action = Keyword.get(collection_actions, action) ->
        collection_action.(conn, params)
      true ->
        apply(__MODULE__, action, [conn, defn, params])
    end
  end

  def handle_before_filter(conn, action, defn, params) do
    case defn.controller_filters[:before_filter] do
      nil ->
        conn
      {name, opts} ->
        filter = cond do
          opts[:only] ->
            if action in opts[:only], do: true, else: false
          opts[:except] ->
            if not action in opts[:except], do: true, else: false
          true -> true
        end
        if filter, do: apply(defn.__struct__, name, [conn, params]), else: conn
    end
  end

  def handle_after_filter(conn, action, defn, params, resource) do
    case defn.controller_filters[:after_filter] do
      nil ->
        {conn, params, resource}
      {name, opts} ->
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
              raise ExAdmin.RuntimeError, message: "invalid after_filter return: #{inspect error}"
          end
        else
          {conn, params, resource}
        end
    end
  end

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
    model = defn.__struct__
    resource = conn.assigns.resource
    conn = Plug.Conn.assign(conn, :ea_required,
       model.__struct__.resource_model.changeset(resource).required)
    {conn, params, resource} = handle_after_filter(conn, :edit, defn, params, resource)
    contents = do_form_view(model, conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
  end

  def new(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource
    conn = Plug.Conn.assign(conn, :ea_required,
       model.__struct__.resource_model.changeset(resource).required)
    {conn, params, resource} = handle_after_filter(conn, :new, defn, params, resource)
    contents = do_form_view(model, conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
  end

  defp do_form_view(model, conn, resource, params) do
    if function_exported? model, :form_view, 3 do
      apply(model, :form_view, [conn, resource, params])
    else
      ExAdmin.Form.default_form_view conn, resource, params
    end
  end

  def create(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource
    resource_model = defn.resource_model |> base_name |> String.downcase |> String.to_atom
    changeset_fn = Keyword.get(defn.changesets, :create, &resource.__struct__.changeset/2)
    changeset = ExAdmin.Repo.changeset(changeset_fn, resource, params[resource_model])

    case ExAdmin.Repo.insert(changeset) do
      {:error, changeset} ->
        errors = if function_exported?(defn.resource_model, :get_errors, 1) do
          apply(defn.resource_model, :get_errors, [changeset])
        else
          changeset.errors
        end
        conn = put_flash(conn, :inline_error, errors)
        |> assign(:ea_required, defn.resource_model.changeset(resource).required)
        |> assign(:changeset, changeset)
        contents = do_form_view model, conn,
          ExAdmin.Changeset.get_data(changeset), params
        conn |> render("admin.html", html: contents, filters: nil)
      resource ->
        {conn, _, resource} = handle_after_filter(conn, :create, defn, params, resource)
        put_flash(conn, :notice, "#{base_name model} was successfully created.")
        |> redirect(to: admin_resource_path(resource, :show))
    end
  end

  def update(conn, defn, params) do
    model = defn.__struct__
    resource_model = defn.resource_model |> base_name |> String.downcase |> String.to_atom
    resource = conn.assigns.resource

    changeset_fn = Keyword.get(defn.changesets, :update, &resource.__struct__.changeset/2)
    changeset1 = ExAdmin.Repo.changeset(changeset_fn, resource, params[resource_model])
    case ExAdmin.Repo.update(changeset1) do
      {:error, changeset} ->
        errors = if function_exported?(defn.resource_model, :get_errors, 1) do
          apply(defn.resource_model, :get_errors, [changeset])
        else
          changeset.errors
        end
        conn = put_flash(conn, :inline_error, errors)
        |> assign(:ea_required, defn.resource_model.changeset(resource).required)
        |> assign(:changeset, changeset)
        contents = do_form_view model, conn,
          ExAdmin.Changeset.get_data(changeset), params
        conn |> render("admin.html", html: contents, filters: nil)
      resource ->
        {conn, _, resource} = handle_after_filter(conn, :update, defn, params, resource)
        put_flash(conn, :notice, "#{base_name model} was successfully updated")
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
    resource_model = defn.resource_model |> base_name |> String.downcase |> String.to_atom
    resource = conn.assigns.resource

    ExAdmin.Repo.delete(resource, params[resource_model])
    resource_model = base_name model

    if conn.assigns.xhr do
      render conn, "destroy.js", tr_id: String.downcase("#{resource_model}_#{params[:id]}")
    else
      put_flash(conn, :notice, "#{resource_model} was successfully destroyed.")
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

    put_flash(conn, :notice, "Successfully destroyed #{count} #{pluralize params[:resource], count}")
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

    query = model.run_query(repo, defn, :csv)
    csv = Authorization.authorize_query(defn, conn, query, :csv, nil)
    |> ExAdmin.Query.execute_query(repo, :csv, nil)
    |> case  do
      [] -> []
      [resource | resources] ->
        ExAdmin.View.Adapter.build_csv(resource, resources)
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
