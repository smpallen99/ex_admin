defmodule ExAdminTest.ControllerTest do
  use TestExAdmin.ConnCase
  require Logger

  import TestExAdmin.TestHelpers
  alias TestExAdmin.{Noid, Map, User, Product, Simple}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    user = insert_user()
    {:ok, user: user}
  end

  test "calls the create changeset when set in resource" do
    TestExAdmin.Simple.start_link()
    conn = post(build_conn(), admin_resource_path(TestExAdmin.Simple, :create), simple: %{})
    assert TestExAdmin.Simple.last_changeset() == "changeset_create"

    TestExAdmin.Simple.stop()
  end

  test "calls the update changeset when set in resource" do
    TestExAdmin.Simple.start_link()
    simple = insert_simple
    conn = patch(build_conn(), admin_resource_path(%Simple{id: simple.id}, :update), simple: %{})

    assert html_response(conn, 302)
    assert TestExAdmin.Simple.last_changeset() == "changeset_update"

    TestExAdmin.Simple.stop()
  end

  test "calls the create changeset when no custom change set is specified and in create path" do
    TestExAdmin.Maps.start_link()
    conn = post(build_conn(), admin_resource_path(TestExAdmin.Maps, :create), map: %{})
    assert TestExAdmin.Maps.last_changeset() == "create_changeset"

    TestExAdmin.Map.stop()
  end

  test "calls the update changeset when no custom change set is specified and in update path" do
    TestExAdmin.Maps.start_link()
    conn = post(build_conn(), admin_resource_path(TestExAdmin.Maps, :create), map: %{})
    assert TestExAdmin.Maps.last_changeset() == "create_changeset"

    TestExAdmin.Maps.stop()
  end
end
