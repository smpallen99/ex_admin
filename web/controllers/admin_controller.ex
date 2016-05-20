defmodule ExAdmin.AdminController do
  @moduledoc false
  use ExAdmin.Web, :controller
  require Logger

  plug :handle_root_req
  plug :set_theme
  plug :set_layout

  # workaround for ExAdmin.get_registered_by_controller_route!
  # ToDo: refactoring of ExAdmin.get_registered_by_controller_route!
  def handle_root_req(conn, _params) do
    conn
    |> struct(params: %{"resource" => "dashboard"})
    |> struct(path_info: ["admin", "dashboard"])
  end

  def dashboard(conn, params) do
    defn = ExAdmin.get_registered_by_controller_route!(conn.params["resource"])
    contents = defn.__struct__ |> apply(:page_view, [conn])

    assign(conn, :scope_counts, [])
    |> render("admin.html", html: contents, defn: defn, resource: nil,
      filters: (if false in defn.index_filters, do: false, else: defn.index_filters))
  end

  def select_theme(conn, %{"id" => id} = params) do
    {id, _} = Integer.parse(id)
    {_, theme} = Application.get_env(:ex_admin, :theme_selector, []) |> Enum.at(id)
    loc = Map.get(params, "loc", admin_path) |> URI.parse |> Map.get(:path)

    Application.put_env :ex_admin, :theme, theme
    redirect conn, to: loc
  end
end
