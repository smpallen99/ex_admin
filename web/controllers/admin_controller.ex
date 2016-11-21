defmodule ExAdmin.AdminController do
  @moduledoc false
  use ExAdmin.Web, :controller
  require Logger

  plug :set_theme
  plug :set_layout

  def page(conn, params) do
    page = Map.get(params, "page", "dashboard")
    defn = get_registered_by_controller_route!(conn, page)
    conn =  assign(conn, :defn, defn)
    contents = defn.__struct__.page_view(conn)

    render(conn, "admin.html", html: contents, resource: nil, scope_counts: [],
      filters: (if false in defn.index_filters, do: false, else: defn.index_filters))
  end
  def dashboard(conn, params) do
    page(conn, Map.put(params, "page", "dashboard"))
  end

  def select_theme(conn, %{"id" => id} = params) do
    {id, _} = Integer.parse(id)
    {_, theme} = Application.get_env(:ex_admin, :theme_selector, []) |> Enum.at(id)
    loc = Map.get(params, "loc", admin_path) |> URI.parse |> Map.get(:path)

    Application.put_env :ex_admin, :theme, theme
    redirect conn, to: loc
  end
end
