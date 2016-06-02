defmodule ExAdmin.BreadCrumbTest do
  use ExUnit.Case, async: true
  alias ExAdmin.BreadCrumb
  import Plug.Conn
  alias TestExAdmin.Simple

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    defn = %TestExAdmin.ExAdmin.Simple{}
    conn = assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
    |> assign(:defn, defn)
    |> struct(path_info: ~w(admin simples))
    |> struct(params: %{})
    {:ok, conn: conn}
  end

  test "get_breadcrumbs index", %{conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :index})
    assert BreadCrumb.get_breadcrumbs(conn, %Simple{}) == [{"/admin", "admin"}]
  end

  test "get_breadcrumbs show", %{conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :show})
    assert BreadCrumb.get_breadcrumbs(conn, %Simple{}) ==
      [{"/admin", "admin"}, {"/admin/simples", "Simples"}]
  end

  test "get_breadcrumbs edit", %{conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :edit})
    assert BreadCrumb.get_breadcrumbs(conn, %Simple{}) ==
      [{"/admin", "admin"}, {"/admin/simples", "Simples"}, {"/admin/simples/", ""}]
  end

  test "get_breadcrumbs new", %{conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :new})
    assert BreadCrumb.get_breadcrumbs(conn, %Simple{}) ==
      [{"/admin", "admin"}, {"/admin/simples", "Simples"}]
  end
end
