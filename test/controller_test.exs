defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.Noid
  alias TestExAdmin.User
  alias TestExAdmin.Product

  @wrong_resource_id 100500
  @wrong_endpoint "/admin/not_existing"

  setup do
    user = insert_user()
    {:ok, user: user}
  end

  test "lists noids", %{user: user} do
    insert_noid(user_id: user.id, name: "controller 1")
    conn =  get conn(), get_route_path(%Noid{}, :index)
    assert html_response(conn, 200) =~ ~r/Noids/
  end

  test "shows correct name for column name with space", %{user: user} do
    insert_noid(%{user_id: user.id, name: "Road Runner", company: "Acme"})
    conn = get conn(), get_route_path(%User{}, :show, user.id)
    assert html_response(conn, 200) =~ ~r/User/
    assert String.contains?(conn.resp_body, ">Road Runner (Acme)<")
  end

  test "shows new product page" do
    conn = get conn(), get_route_path(%Product{}, :new), []
    assert html_response(conn, 200) =~ "New Product"
  end

  @invalid_attrs %{}
  test "does not create resource and renders errors when data is invalid" do
    conn = post conn(), get_route_path(%Product{}, :create), product: @invalid_attrs
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
    conn = get conn(), get_route_path(%User{}, :show, @wrong_resource_id)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for PATCH missing resource" do
    conn = patch conn(), get_route_path(%User{}, :edit, @wrong_resource_id)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for PUT missing resource" do
    conn = put conn(), get_route_path(%User{}, :edit, @wrong_resource_id)
    assert html_response(conn, 404) =~ ~r/not found/
  end

  test "shows 404 for DELETE missing resource" do
    conn = delete conn(), get_route_path(%User{}, :delete, @wrong_resource_id)
    assert html_response(conn, 404) =~ ~r/not found/
  end
end
