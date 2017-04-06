defmodule ExAdmin.AdminResourceController do
  @moduledoc false
  @resource nil

  use ExAdmin.Web, :resource_controller
  import ExAdmin.Index

  def index(conn, defn, params) do
    model = defn.__struct__

    page = case conn.assigns[:page] do
      nil ->
        id = params |> Map.to_list
        query = model.run_query(repo(), defn, :index, id)
        Authorization.authorize_query(conn.assigns.resource, conn, query, :index, id)
        |> ExAdmin.Query.execute_query(repo(), :index, id)

      page ->
        page
    end
    scope_counts = model.run_query_counts repo(), defn, :index, params |> Map.to_list

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

    changeset_fn = model.changeset_fn(defn, :update)
    changeset = ExAdmin.Repo.changeset(changeset_fn, resource, params[defn.resource_name])

    conn = Plug.Conn.assign(conn, :ea_required, changeset.required)
    {conn, params, resource} = handle_after_filter(conn, :edit, defn, params, resource)
    contents = do_form_view(conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
  end

  def new(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    changeset_fn = model.changeset_fn(defn, :create)
    changeset = ExAdmin.Repo.changeset(changeset_fn, resource, params[defn.resource_name])

    conn = Plug.Conn.assign(conn, :ea_required, changeset.required)
    {conn, params, resource} = handle_after_filter(conn, :new, defn, params, resource)
    contents = do_form_view(conn, resource, params)

    render conn, "admin.html", html: contents, filters: nil
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
        put_flash(conn, :notice, (gettext "%{model_name} was successfully created.", model_name: (model |> base_name |> titleize) ))
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
        put_flash(conn, :notice, "#{model |> base_name |> titleize} " <> (gettext "was successfully updated."))
        |> redirect(to: admin_resource_path(resource, :show))
    end
  end

  def toggle_attr(conn, defn, %{attr_name: attr_name, attr_value: attr_value}) do
    resource = conn.assigns.resource
    attr_name_atom = String.to_existing_atom(attr_name)

    resource = resource
    |> defn.resource_model.changeset(%{attr_name => attr_value})
    |> repo().update!

    render conn, "toggle_attr.js", attr_name: attr_name, attr_value: Map.get(resource, attr_name_atom), id: ExAdmin.Schema.get_id(resource)
  end

  def destroy(conn, defn, params) do
    model = defn.__struct__
    resource = conn.assigns.resource

    ExAdmin.Repo.delete(resource, params[defn.resource_name])
    page =
      case conn.assigns[:page] do
        nil ->
          id = params |> Map.to_list
          query = model.run_query(repo(), defn, :index, id)
          Authorization.authorize_query(conn.assigns.resource, conn, query, :index, id)
          |> ExAdmin.Query.execute_query(repo(), :index, id)
        page ->
          page
      end

    page_number = params[:page] || page.page_number
    opts = %{
      href: admin_resource_path(conn, :index) <> "?order=",
      order: ExQueb.get_sort_order(conn.params["order"])
    }
    model_name = model |> base_name |> titleize
    model_id = model |> base_name |> Inflex.underscore
    pagination =
      opts[:href]
      |> build_scope_href(conn.params["scope"])
      |> build_order_href(opts[:order])
      |> build_filter_href(conn.params["q"])
      |> ExAdmin.Paginate.paginate(page_number, page.page_size, page.total_pages, page.total_entries, "#{model_name}")

    {conn, _, _resource} = handle_after_filter(conn, :destroy, defn, params, resource)
    if conn.assigns.xhr do
      render conn, "destroy.js", tr_id: String.downcase("#{model_id}_#{params[:id]}"), pagination: pagination

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
      repo().delete repo().get(resource_model, id)
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
    query = model.run_query(repo(), defn, :csv, id)
    csv = Authorization.authorize_query(conn.assigns.resource, conn, query, :csv, id)
    |> ExAdmin.Query.execute_query(repo(), :csv, id)
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

  # Can't remember why this is here
  # @nested_key_list for i <- 1..5, do: {String.to_atom("nested#{i}"), String.to_atom("id#{i}")}

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

end
