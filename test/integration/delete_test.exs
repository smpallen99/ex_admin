defmodule TestExAdmin.DeleteTest do
  use TestExAdmin.AcceptanceCase
  alias TestExAdmin.{Noid}

  hound_session()
  # Start hound session and destroy when tests are run
  setup do
    user = insert_user()
    {:ok, user: user}
  end

  #
  # This test is pending PhantomJS dialog support
  # https://github.com/detro/ghostdriver/issues/20
  #
  @tag :pending
  test "delete a noid", %{user: user} do
    noid = insert_noid(user_id: user.id, name: "controller 1")
    _user2 = insert_user()
    current_window_handle() |> maximize_window
    navigate_to(admin_resource_path(Noid, :index))

    assert page_source() =~ noid.name
    click(find_element(:class, "delete_link"))

    assert dialog_text() == "Are you sure you want to delete this?"
    accept_dialog()

    assert current_url() == admin_resource_path(Noid, :index)
    refute page_source() =~ noid.name
  end
end
