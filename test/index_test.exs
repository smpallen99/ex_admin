defmodule ExAdminTest.IndexTest do
  use TestExAdmin.ConnCase
  alias ExAdmin.Index

  def setup_conn(defn, resource, params \\ %{}) do
    Plug.Conn.assign(conn(), :defn, defn)
    |> Plug.Conn.assign(:resource, resource)
    |> Plug.Conn.assign(:theme, ExAdmin.Theme.AdminLte2)
    |> struct(params: params)
  end

  setup do
    resource = %TestExAdmin.Simple{id: 1, name: "Test", description: "Something"}
    defn = %TestExAdmin.ExAdmin.Simple{}
    page = %Scrivener.Page{entries: [resource], page_number: 1, page_size: 20, total_entries: 1, total_pages: 1}
    {:ok, resource: resource, defn: defn, page: page}
  end

  test "default_index_view", %{resource: resource, defn: defn, page: page} do
    conn = setup_conn defn, resource
    {:safe, html} = Index.default_index_view conn, page, []
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end

  test "default_index_view with filter list", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[:name, :description]])
    conn = setup_conn defn, resource
    {:safe, html} = Index.default_index_view conn, page, []
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end
  test "default_index_view with filter only", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[only: [:name, :description]]])
    conn = setup_conn defn, resource
    {:safe, html} = Index.default_index_view conn, page, []
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end
  test "default_index_view with filter except", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[except: [:description]]])
    conn = setup_conn defn, resource
    {:safe, html} = Index.default_index_view conn, page, []
    assert floki_text(html, "td.td-name", "Test")
    assert Floki.find(html, "td.td-description") == []
  end
  test "default_index_view with filter labels", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[labels: [name: "name"]]])
    conn = setup_conn defn, resource
    {:safe, html} = Index.default_index_view conn, page, []
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end

  defp floki_text(html, selector, text) do
    Floki.find(html, selector) |> Floki.text == text
  end
end
