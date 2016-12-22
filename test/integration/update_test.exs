defmodule TestExAdmin.UpdateTest do
  use TestExAdmin.AcceptanceCase
  alias TestExAdmin.{Noid}

  hound_session()
  # Start hound session and destroy when tests are run
  setup do
    user = insert_user()
    {:ok, user: user}
  end

  @tag :integration
  test "edit a noid updates correct data", %{user: user} do
    noid = insert_noid(user_id: user.id, name: "controller 1")
    _user2 = insert_user()
    current_window_handle() |> maximize_window
    navigate_to admin_resource_path(Noid, :index)
    click(find_element(:class, "edit_link"))

    name_field = find_element(:name, "noid[name]")
    description_field = find_element(:name, "noid[description]")
    company_field = find_element(:name, "noid[company]")
    user_field = find_element(:name, "noid[user_id]")

    assert attribute_value(name_field, "value") == noid.name
    assert attribute_value(description_field, "value") == noid.description
    assert attribute_value(company_field, "value") == noid.company
    assert attribute_value(user_field, "value") == "#{noid.user_id}"

    fill_field name_field, "Cory"
    fill_field description_field, "Updated"
    fill_field company_field, "This"

    click(find_element(:name, "commit"))

    assert visible_text(find_element(:class, "td-name")) == "Cory"
    assert visible_text(find_element(:class, "td-description")) == "Updated"
    assert visible_text(find_element(:class, "td-company")) == "This"
  end
end
