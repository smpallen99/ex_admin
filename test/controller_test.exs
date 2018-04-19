defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.{Noid, User, Product, Simple}

  @wrong_resource_id 100_500
  @wrong_endpoint "/admin/not_existing"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    user = insert_user()
    {:ok, user: user}
  end

  test "lists noids", %{user: user} do
    insert_noid(user_id: user.id, name: "controller 1")
    conn = get(build_conn(), admin_resource_path(Noid, :index))
    assert html_response(conn, 200) =~ ~r/Noids/
    assert conn.resp_body =~ ~r/View/
    assert conn.resp_body =~ ~r/Edit/
    assert conn.resp_body =~ ~r/Delete/
  end

  test "lists noids with user w/o name" do
    insert_user(%{name: nil, email: "nil@example.com"})
    conn = get(build_conn(), admin_resource_path(Noid, :index))
    assert html_response(conn, 200) =~ ~r/Noids/
  end

  test "shows correct name for column name with space", %{user: user} do
    insert_noid(%{user_id: user.id, name: "Road Runner", company: "Acme"})
    conn = get(build_conn(), admin_resource_path(user, :show))
    assert html_response(conn, 200) =~ ~r/User/
    assert String.contains?(conn.resp_body, ">Road Runner (Acme)<")
  end

  test "shows multiple table_for and markup_contents sections", %{user: user} do
    conn = get(build_conn(), admin_resource_path(user, :show))

    assert conn.resp_body =~
             ~r(<h3>First table</h3>.*<p>With some No-ID entries</p>.*<table.*</table>.*<table.*</table>.*<h3>\^\^ Second table</h3>)sm
  end

  test "shows new product page" do
    conn = get(build_conn(), admin_resource_path(Product, :new), [])
    assert html_response(conn, 200) =~ "New Product"
  end

  @invalid_attrs %{}
  test "does not create resource and renders errors when data is invalid" do
    conn = post(build_conn(), admin_resource_path(Product, :create), product: @invalid_attrs)
    assert html_response(conn, 200) =~ "New Product"
    assert String.contains?(conn.resp_body, "can't be blank")
  end

  test "does not create resource and sets changeset" do
    conn = post(build_conn(), admin_resource_path(Product, :create), product: @invalid_attrs)
    assert html_response(conn, 200) =~ "New Product"
    assert conn.assigns[:changeset].changes == %{}
  end

  test "does not create resource and required fields" do
    conn = post(build_conn(), admin_resource_path(Product, :create), product: @invalid_attrs)
    assert html_response(conn, 200) =~ "New Product"

    refute Floki.find(conn.resp_body, "#product_title_input abbr") == []
  end

  # TODO: Need to fix this test case
  # test "shows 404 for GET missing endpoint" do
  #   conn = get build_conn(), @wrong_endpoint
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  # TODO: Need to fix this test case
  # test "shows 404 for POST missing endpoint" do
  #   conn = post build_conn(), @wrong_endpoint
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  # TODO: Need to fix this test case
  # test "shows 404 for GET missing resource" do
  #   conn = get build_conn(), admin_resource_path(%User{id: @wrong_resource_id}, :show)
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  # TODO: Need to fix this test case
  # test "shows 404 for PATCH missing resource" do
  #   conn = patch build_conn(), admin_resource_path(%User{id: @wrong_resource_id}, :edit)
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  # TODO: Need to fix this test case
  # test "shows 404 for PUT missing resource" do
  #   conn = put build_conn(), admin_resource_path(%User{id: @wrong_resource_id}, :edit)
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  # TODO: Need to fix this test case
  # test "shows 404 for DELETE missing resource" do
  #   conn = delete build_conn(), admin_resource_path(%User{id: @wrong_resource_id}, :destroy)
  #   assert html_response(conn, 404) =~ ~r/not found/
  # end

  def batch_action_args(resource, id) do
    %{batch_action: "destroy", resource: resource, collection_selection: ["#{id}"]}
  end

  test "batch selection", %{user: user} do
    params = batch_action_args("users", user.id)
    conn = post(build_conn(), admin_resource_path(User, :batch_action), params)
    assert html_response(conn, 302)
  end

  test "batch selection for binary id" do
    noid =
      TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, %{name: "testing", description: "desc"})
      |> TestExAdmin.Repo.insert!()

    params = batch_action_args("noids", noid.name)
    conn = post(build_conn(), "/admin/noids/batch_action", params)
    assert html_response(conn, 302)
  end

  @valid_attrs %{title: "title", price: "19.99"}
  test "create and update after callback" do
    user = Repo.all(User) |> hd
    conn = post(build_conn(), admin_resource_path(Product, :create), product: @valid_attrs)
    product = conn.assigns[:product]
    assert html_response(conn, 302)
    assert product.user_id == user.id
    assert conn.assigns[:before_both] == :yes
    refute conn.assigns[:before_update] == :yes
    assert conn.assigns[:after_create] == :yes
    refute conn.assigns[:after_update] == :yes
    refute conn.assigns[:after_update2] == :yes

    conn = put(build_conn(), admin_resource_path(product, :update), product: @valid_attrs)
    assert conn.assigns[:answer] == 42
    assert conn.assigns[:before_both] == :yes
    assert conn.assigns[:before_update] == :yes
    refute conn.assigns[:after_create] == :yes
    assert conn.assigns[:after_update] == :yes
    assert conn.assigns[:after_update2] == :yes
  end

  test "new form" do
    TestExAdmin.Simple.start_link()
    conn = get(build_conn(), admin_resource_path(Simple, :new), %{})
    assert html_response(conn, 200) =~ ~r/New Simple/
    refute Floki.find(conn.resp_body, "input#simple_name") == []
    TestExAdmin.Simple.stop()
  end

  test "restricted actions" do
    restricted = insert_restricted()

    conn = get(build_conn(), admin_resource_path(TestExAdmin.Restricted, :index))
    assert html_response(conn, 200) =~ ~r/Simple/

    conn = get(build_conn(), admin_resource_path(TestExAdmin.Restricted, :new))
    assert html_response(conn, 403) =~ ~r/Forbidden Request/

    conn = get(build_conn(), admin_resource_path(restricted, :edit), %{})
    assert html_response(conn, 403) =~ ~r/Forbidden Request/

    conn = post(build_conn(), ExAdmin.Utils.admin_resource_path(TestExAdmin.Restricted, :create))
    assert html_response(conn, 403) =~ ~r/Forbidden Request/

    conn = delete(build_conn(), admin_resource_path(restricted, :destroy))
    assert html_response(conn, 403) =~ ~r/Forbidden Request/
  end
end
