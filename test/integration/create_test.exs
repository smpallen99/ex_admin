defmodule TestExAdmin.CreateTest do
  use TestExAdmin.AcceptanceCase
  alias TestExAdmin.{User, Product}

  hound_session()
  # Start hound session and destroy when tests are run
  setup do
    old_theme = Application.get_env(:ex_admin, :theme)

    on_exit(fn ->
      Application.put_env(:ex_admin, :theme, old_theme)
    end)

    user = insert_user()
    current_window_handle() |> maximize_window
    {:ok, user: user}
  end

  for x <- [ExAdmin.Theme.ActiveAdmin, ExAdmin.Theme.AdminLte2] do
    Application.put_env(:ex_admin, :theme, x)

    @tag :integration
    test "create a product #{x}", %{user: user} do
      navigate_to(admin_resource_path(Product, :new))

      title_field = find_element(:name, "product[title]")
      price_field = find_element(:name, "product[price]")
      _user_field = find_element(:name, "product[user_id]")

      fill_field(title_field, "Test Create")
      fill_field(price_field, ".99")

      find_element(:css, "select[name*='product[user_id]']")
      |> find_all_within_element(:css, "option")
      |> Enum.find(fn x -> attribute_value(x, "value") == "#{user.id}" end)
      |> click

      click(find_element(:name, "commit"))

      assert visible_text(find_element(:class, "td-title")) == "Test Create"
      assert visible_text(find_element(:class, "td-price")) == "0.99"
      assert visible_text(find_element(:class, "td-user")) == user.name
    end

    @tag :integration
    test "validate product creation  #{x}" do
      navigate_to(admin_resource_path(Product, :new))
      click(find_element(:name, "commit"))

      title_wrapper = find_element(:css, "#product_title_input")
      price_wrapper = find_element(:css, "#product_price_input")
      assert visible_text(title_wrapper) == "Title*\ncan't be blank"
      assert visible_text(price_wrapper) == "Price*\ncan't be blank"
    end

    @tag :integration
    test "has many through with many to many realtionship form #{x} " do
      role = insert_role()
      role2 = insert_role(%{name: "Test2"})
      navigate_to(admin_resource_path(User, :new))

      name_field = find_element(:css, "#user_name")
      email_field = find_element(:css, "#user_email")
      role_field = find_element(:css, "input[name*='user[role_ids][#{role.id}]']")
      role_field2 = find_element(:css, "input[name*='user[role_ids][#{role2.id}]']")

      products_wrapper = find_element(:css, ".products")
      products_adder = find_all_within_element(products_wrapper, :css, ".btn-primary")

      click(role_field)
      click(role_field2)
      fill_field(name_field, "Cory")
      fill_field(email_field, "test@example.com")

      click(List.first(products_adder))

      product_fields = find_all_within_element(products_wrapper, :css, "input[type='text']")

      fill_field(List.first(product_fields), "A product title")
      fill_field(Enum.at(product_fields, 1), "13.00")

      click(find_element(:name, "commit"))

      user =
        Repo.one(from(x in User, order_by: [desc: x.id], limit: 1))
        |> Repo.preload(:roles)
        |> Repo.preload(:products)

      assert Enum.count(user.products) == 1
      assert Enum.member?(user.roles, role)
    end

    @tag :integration
    test "has many through realtionship form #{x} " do
    end
  end
end
