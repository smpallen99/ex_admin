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
    navigate_to(admin_resource_path(Noid, :index))
    click(find_element(:class, "edit_link"))

    name_field = find_element(:name, "noid[name]")
    description_field = find_element(:name, "noid[description]")
    company_field = find_element(:name, "noid[company]")
    user_field = find_element(:name, "noid[user_id]")

    assert attribute_value(name_field, "value") == noid.name
    assert attribute_value(description_field, "value") == noid.description
    assert attribute_value(company_field, "value") == noid.company
    assert attribute_value(user_field, "value") == "#{noid.user_id}"

    fill_field(name_field, "Cory")
    fill_field(description_field, "Updated")
    fill_field(company_field, "This")

    click(find_element(:name, "commit"))

    assert visible_text(find_element(:class, "td-name")) == "Cory"
    assert visible_text(find_element(:class, "td-description")) == "Updated"
    assert visible_text(find_element(:class, "td-company")) == "This"
  end

  @tag :integration
  test "has many through with many to many realtionship destroy relation " do
    role = insert_role()
    role2 = insert_role(%{name: "Test2"})

    user = insert_user(%{roles: [role.id, role2.id]})
    _product = insert_product(%{user_id: user.id})

    user = get_user(user.id)

    assert Enum.count(user.products) == 1
    assert Enum.count(user.roles) == 2

    navigate_to(admin_resource_path(user, :edit))

    name_field = find_element(:css, "#user_name")
    email_field = find_element(:css, "#user_email")
    products_wrapper = find_element(:css, ".products")
    _products_adder = find_all_within_element(products_wrapper, :css, ".btn-primary")

    execute_script(
      "document.getElementsByName('user[role_ids][#{role2.id}]')[0].checked = false;"
    )

    fill_field(name_field, "Cory")
    fill_field(email_field, "test@example.com")

    execute_script(
      "document.getElementsByName('user[products_attributes][0][_destroy]')[0].checked = true;"
    )

    click(find_element(:name, "commit"))
    user = get_user(user.id)

    assert Enum.count(user.products) == 1
    refute Enum.member?(user.roles, role2)
  end

  @tag :integration
  test "validate product creation many to many " do
    role = insert_role()
    role2 = insert_role(%{name: "Test2"})

    user = insert_user(%{roles: [role.id, role2.id]})
    _product = insert_product(%{user_id: user.id})

    user = get_user(user.id)

    assert Enum.count(user.products) == 1
    assert Enum.count(user.roles) == 2

    navigate_to(admin_resource_path(user, :edit))

    product_title = find_element(:name, "user[products_attributes][0][title]")
    fill_field(product_title, "")
    click(find_element(:name, "commit"))

    product_title = find_element(:name, "user[products_attributes][0][title]")

    title_wrapper = find_element(:css, "#user_products_attributes_0_title_input")
    assert visible_text(product_title) == ""
    assert visible_text(title_wrapper) == "Title\ncan't be blank"
  end

  @tag :integration
  test "update with errors keeps checkbox state " do
    role = insert_role()
    role2 = insert_role(%{name: "Test2"})

    user = insert_user(%{roles: [role.id, role2.id]})

    user = get_user(user.id)

    assert Enum.count(user.roles) == 2

    navigate_to(admin_resource_path(user, :edit))

    email_field = find_element(:css, "#user_email")

    execute_script(
      "document.getElementsByName('user[role_ids][#{role2.id}]')[0].checked = false;"
    )

    fill_field(email_field, "")

    click(find_element(:name, "commit"))

    role_field = find_element(:css, "input[name*='user[role_ids][#{role.id}]']")
    role_field2 = find_element(:css, "input[name*='user[role_ids][#{role2.id}]']")
    assert attribute_value(role_field2, "checked") == nil
    assert attribute_value(role_field, "checked") == "true"
  end

  @tag :integration
  test "remove has many association and error occurs" do
    role = insert_role()
    role2 = insert_role(%{name: "Test2"})

    user = insert_user(%{roles: [role.id, role2.id]})
    product = insert_product(%{user_id: user.id})

    user = get_user(user.id)

    assert Enum.count(user.products) == 1
    assert Enum.count(user.roles) == 2

    navigate_to(admin_resource_path(user, :edit))

    email_field = find_element(:css, "#user_email")

    products_wrapper = find_element(:css, ".products")
    _products_adder = find_all_within_element(products_wrapper, :css, ".btn-primary")

    fill_field(email_field, "")

    execute_script("document.getElementsByClassName('destroy')[0].checked = true")

    click(find_element(:name, "commit"))

    products_wrapper = find_element(:css, ".products")
    product_destroy = find_within_element(products_wrapper, :css, ".destroy")

    product_title =
      find_within_element(products_wrapper, :name, "user[products_attributes][0][title]")

    assert attribute_value(product_title, "value") == product.title
    assert attribute_value(product_destroy, "checked") == "true"
  end

  defp get_user(id) do
    Repo.get!(TestExAdmin.User, id)
    |> Repo.preload(:roles)
    |> Repo.preload(:products)
  end
end
