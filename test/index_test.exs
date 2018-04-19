defmodule TestExAdmin.SimpleIndexTest do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    index do
      selectable_column()
      column(:name)
      column(:description)
      column(:exists?)

      actions([:show, :edit])
    end
  end
end

defmodule ExAdminTest.IndexTest do
  use TestExAdmin.ConnCase
  alias ExAdmin.Index

  def setup_conn(defn, resource, params \\ %{}) do
    Plug.Conn.assign(build_conn(), :defn, defn)
    |> Plug.Conn.assign(:resource, resource)
    |> Plug.Conn.assign(:theme, ExAdmin.Theme.AdminLte2)
    |> struct(params: params)
  end

  setup config do
    defn =
      case config[:as_resource] do
        nil -> %TestExAdmin.ExAdmin.Simple{}
        other -> other
      end

    resource =
      struct(defn.resource_model.__struct__, %{
        id: 1,
        name: "Test",
        description: "Something",
        exists?: true
      })

    page = %Scrivener.Page{
      entries: [resource],
      page_number: 1,
      page_size: 20,
      total_entries: 1,
      total_pages: 1
    }

    {:ok, resource: resource, defn: defn, page: page}
  end

  @tag as_resource: %TestExAdmin.SimpleIndexTest{}
  test "renders boolean titles with ? properly", %{resource: resource, defn: defn, page: page} do
    conn = setup_conn(defn, resource)
    {:safe, html} = TestExAdmin.SimpleIndexTest.index_view(conn, page, [])
    assert floki_text(html, ".th-exists", "Exists?")
  end

  test "default_index_view", %{resource: resource, defn: defn, page: page} do
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end

  test "default_index_view with filter list", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[:name, :description]])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end

  test "default_index_view with filter labels", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, index_filters: [[:description, name: [label: "name"]]])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])
    assert floki_text(html, "td.td-name", "Test")
    assert floki_text(html, "td.td-description", "Something")
  end

  test "default actions default page", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [:new, :edit, :show, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 3
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Edit"
    assert Enum.at(links, 2) |> Floki.text() == "Delete"
  end

  # def render_index_pages(conn, page, scope_counts, cell, page_opts) do

  @tag as_resource: %TestExAdmin.SimpleIndexTest{}
  test "default actions with index macro", %{resource: resource, defn: defn, page: page} do
    # defn = struct(defn, actions: [:new, :edit, :show, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = TestExAdmin.SimpleIndexTest.index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 2
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Edit"
  end

  test "restricted edit action default page", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [:new, :show, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 2
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Delete"
  end

  @tag as_resource: %TestExAdmin.SimpleIndexTest{}
  test "restricted edit action with index macro", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [:new, :show, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = TestExAdmin.SimpleIndexTest.index_view(conn, page, [])
    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 1
    assert Enum.at(links, 0) |> Floki.text() == "View"
  end

  test "restricted delete action", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [:new, :show, :edit])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 2
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Edit"
  end

  test "custom action", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [{:index, [{:fn, [:test]}]}, :new, :show, :edit, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 3
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Edit"
    assert Enum.at(links, 2) |> Floki.text() == "Delete"
  end

  @tag as_resource: %TestExAdmin.SimpleIndexTest{}
  test "custom action with index macro", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [{:index, [{:fn, [:test]}]}, :new, :show, :edit, :delete])
    conn = setup_conn(defn, resource)
    {:safe, html} = TestExAdmin.SimpleIndexTest.index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 2
    assert Enum.at(links, 0) |> Floki.text() == "View"
    assert Enum.at(links, 1) |> Floki.text() == "Edit"
  end

  test "custom and restricted action", %{resource: resource, defn: defn, page: page} do
    defn = struct(defn, actions: [{:index, [{:fn, [:test]}]}, :show])
    conn = setup_conn(defn, resource)
    {:safe, html} = Index.default_index_view(conn, page, [])

    links = Floki.find(html, "td.td-actions a")

    assert Enum.count(links) == 1
    assert Enum.at(links, 0) |> Floki.text() == "View"
  end

  test " get_index_actions", %{resource: _resource, defn: defn, page: _page} do
    assert struct(defn, actions: [:show, :new, :edit, :delete])
           |> Index.get_index_actions([]) == [:show, :edit, :delete]

    assert struct(defn, actions: [{:show, {:fn, [:test]}}, :show, :new, :edit, :delete])
           |> Index.get_index_actions([]) == [:show, :edit, :delete]
  end

  test "action_items overrides actions", %{resource: _resource, defn: defn, page: _page} do
    assert struct(defn, actions: [:show])
           |> Index.get_index_actions([:edit, :show]) == [:show]

    assert struct(defn, actions: [{:index, {:fn, [:test]}}, :show])
           |> Index.get_index_actions([:edit, :show]) == [:show]
  end

  defp floki_text(html, selector, text) do
    Floki.find(html, selector) |> Floki.text() == text
  end
end
