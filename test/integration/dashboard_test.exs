defmodule TestExAdmin.DashboardIntegrationTest do
  use TestExAdmin.AcceptanceCase
  alias TestExAdmin.{Noid, User, Product, Simple}
  alias Hound.Element

  hound_session

  @tag :integration
  test "gets dashboard" do
    navigate_to "/admin"
    assert(String.contains? visible_page_text, "dashboard")
  end

  @tag :integration
  test "dashboard shows sidebar" do
    navigate_to "/admin"
    assert(String.contains? visible_page_text, "Test Sidebar")
    assert(String.contains? visible_page_text, "This is a test.")
  end
end
