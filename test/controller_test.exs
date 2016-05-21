defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.{Noid, User, Product}

  @wrong_resource_id 100500
  @wrong_endpoint "/admin/not_existing"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    user = insert_user()
    {:ok, user: user}
  end

  test "lists noids", %{user: user} do
    insert_noid(user_id: user.id, name: "controller 1")
    conn =  get conn(), admin_resource_path(Noid, :index)
    assert html_response(conn, 200) =~ ~r/Noids/
  end

  test "shows correct name for column name with space", %{user: user} do
    insert_noid(%{user_id: user.id, name: "Road Runner", company: "Acme"})
    conn = get conn(), admin_resource_path(user, :show)
    assert html_response(conn, 200) =~ ~r/User/
    assert String.contains?(conn.resp_body, ">Road Runner (Acme)<")
  end

  test "shows multiple table_for and markup_contents sections", %{user: user} do
    conn = get conn(), admin_resource_path(user, :show)
    assert conn.resp_body =~ ~r(<h3>First table</h3>.*<p>With some No-ID entries</p>.*<table.*</table>.*<table.*</table>.*<h3>\^\^ Second table</h3>)sm
  end

  test "shows new product page" do
    conn = get conn(), admin_resource_path(Product, :new), []
    assert html_response(conn, 200) =~ "New Product"
  end

  @invalid_attrs %{}
  test "does not create resource and renders errors when data is invalid" do
    conn = post conn(), admin_resource_path(Product, :create), product: @invalid_attrs
    assert html_response(conn, 200) =~ "New Product"
    assert String.contains?(conn.resp_body, "can't be blank")
  end

  test "shows 404 for GET missing endpoint" do
    conn = get conn(), @wrong_endpoint
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for POST missing endpoint" do
    conn = post conn(), @wrong_endpoint
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for GET missing resource" do
    conn = get conn(), admin_resource_path(%User{id: @wrong_resource_id}, :show)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for PATCH missing resource" do
    conn = patch conn(), admin_resource_path(%User{id: @wrong_resource_id}, :edit)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for PUT missing resource" do
    conn = put conn(), admin_resource_path(%User{id: @wrong_resource_id}, :edit)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for DELETE missing resource" do
    conn = delete conn(), admin_resource_path(%User{id: @wrong_resource_id}, :destroy)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  def batch_action_args(resource, id) do
    %{batch_action: "destroy", resource: resource, collection_selection: ["#{id}"]}
  end

  test "batch selection", %{user: user} do
    params = batch_action_args "users", user.id
    conn = post conn(), admin_resource_path(User, :batch_action), params
    assert html_response(conn, 302)
  end

  test "batch selection for binary id" do
    noid = TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, %{name: "testing", description: "desc"})
    |> TestExAdmin.Repo.insert!
    params = batch_action_args "noids", noid.name
    conn = post conn(), "/admin/noids/batch_action", params
    assert html_response(conn, 302)
  end

  @valid_attrs %{title: "title", price: "19.99"}
  test "create and update after callback" do
    user = Repo.all(User) |> hd
    conn = post conn(), admin_resource_path(Product, :create), product: @valid_attrs
    product = conn.assigns[:product]
    assert html_response(conn, 302)
    assert product.user_id == user.id

    conn = put conn(), admin_resource_path(product, :update), product: @valid_attrs
    assert conn.assigns[:answer] == 42
  end

end
