defmodule ExAdminTest.DashboardTest do
  use TestExAdmin.ConnCase
  require Logger

  # import TestExAdmin.TestHelpers

  # setup do
  #   user = insert_user()
  #   {:ok, user: user}
  # end

  test "gets dashboard" do
    conn = get(build_conn(), "/admin/page/dashboard")
    assert html_response(conn, 200) =~ "Dashboard"

    conn = get(build_conn(), "/admin")
    assert html_response(conn, 200) =~ "Dashboard"
  end

  test "dashboard shows sidebar" do
    conn = get(build_conn(), "/admin")
    assert html_response(conn, 200) =~ "Dashboard"
    assert String.contains?(conn.resp_body, "Test Sidebar")
    assert String.contains?(conn.resp_body, "This is a test.")
  end
end
