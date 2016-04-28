defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.Noid
  alias TestExAdmin.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
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
end
