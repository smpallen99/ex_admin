defmodule ExAdmin.BreadCrumbTest do
  use ExUnit.Case, async: true
  alias ExAdmin.BreadCrumb
  import Plug.Conn
  alias TestExAdmin.{Simple, ModelDisplayName, DefnDisplayName}

  describe "no display name overrides" do
    setup [:simple_setup]

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

  describe "model display_name override" do
    setup [:model_display_name]

    test "get_breadcrumbs index", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :index})
      assert BreadCrumb.get_breadcrumbs(conn, %ModelDisplayName{}) == [{"/admin", "admin"}]
    end

    test "get_breadcrumbs show", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :show})

      assert BreadCrumb.get_breadcrumbs(conn, %ModelDisplayName{}) ==
               [{"/admin", "admin"}, {"/admin/model_display_names", "ModelDisplayNames"}]
    end

    test "get_breadcrumbs edit", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :edit})
      resource = %ModelDisplayName{id: 1, first: "one", name: "two", other: "three"}

      assert BreadCrumb.get_breadcrumbs(conn, resource) ==
               [
                 {"/admin", "admin"},
                 {"/admin/model_display_names", "ModelDisplayNames"},
                 {"/admin/model_display_names/1", "three"}
               ]
    end

    test "get_breadcrumbs new", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :new})

      assert BreadCrumb.get_breadcrumbs(conn, %ModelDisplayName{}) ==
               [{"/admin", "admin"}, {"/admin/model_display_names", "ModelDisplayNames"}]
    end
  end

  describe "defn display_name override" do
    setup [:defn_display_name]

    test "get_breadcrumbs index", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :index})
      assert BreadCrumb.get_breadcrumbs(conn, %DefnDisplayName{}) == [{"/admin", "admin"}]
    end

    test "get_breadcrumbs show", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :show})

      assert BreadCrumb.get_breadcrumbs(conn, %DefnDisplayName{}) ==
               [{"/admin", "admin"}, {"/admin/defn_display_names", "DefnDisplayNames"}]
    end

    test "get_breadcrumbs edit", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :edit})
      resource = %DefnDisplayName{id: 1, first: "one", second: "two", name: "three"}

      assert BreadCrumb.get_breadcrumbs(conn, resource) ==
               [
                 {"/admin", "admin"},
                 {"/admin/defn_display_names", "DefnDisplayNames"},
                 {"/admin/defn_display_names/1", "two"}
               ]
    end

    test "get_breadcrumbs new", %{conn: conn} do
      conn = struct(conn, private: %{phoenix_action: :new})

      assert BreadCrumb.get_breadcrumbs(conn, %DefnDisplayName{}) ==
               [{"/admin", "admin"}, {"/admin/defn_display_names", "DefnDisplayNames"}]
    end
  end

  def simple_setup(_) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    defn = %TestExAdmin.ExAdmin.Simple{}

    conn =
      assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
      |> assign(:defn, defn)
      |> struct(path_info: ~w(admin simples))
      |> struct(params: %{})

    {:ok, conn: conn}
  end

  def model_display_name(_) do
    defn = %TestExAdmin.ExAdmin.ModelDisplayName{}

    conn =
      assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
      |> assign(:defn, defn)
      |> struct(path_info: ~w(admin model_display_names))
      |> struct(params: %{})

    {:ok, conn: conn}
  end

  def defn_display_name(_) do
    defn = %TestExAdmin.ExAdmin.DefnDisplayName{}

    conn =
      assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
      |> assign(:defn, defn)
      |> struct(path_info: ~w(admin defn_display_names))
      |> struct(params: %{})

    {:ok, conn: conn}
  end
end
