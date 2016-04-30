defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.Noid
  alias TestExAdmin.User
  alias TestExAdmin.Product

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
end
