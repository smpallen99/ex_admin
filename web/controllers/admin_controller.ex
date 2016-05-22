defmodule ExAdmin.AdminController do
  @moduledoc false
  use ExAdmin.Web, :controller
  require Logger

  plug :set_theme
  plug :set_layout


  def dashboard(conn, params) do
    defn = get_registered_by_controller_route!(conn, "dashboard")
    contents = defn.__struct__ |> apply(:page_view, [conn])

    conn
    |> assign(:defn, defn)
    |> assign(:scope_counts, [])
    |> render("admin.html", html: contents, defn: defn, resource: nil,
      filters: (if false in defn.index_filters, do: false, else: defn.index_filters))
  end

  def select_theme(conn, %{"id" => id} = params) do
    {id, _} = Integer.parse(params["id"])
    {_, theme} = Application.get_env(:ex_admin, :theme_selector, []) |> Enum.at(id)
    loc = Map.get(params, "loc", admin_path) |> URI.parse |> Map.get(:path)

    Application.put_env :ex_admin, :theme, theme
    redirect conn, to: loc
  end
end
