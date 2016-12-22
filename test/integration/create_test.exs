defmodule TestExAdmin.CreateTest do
  use TestExAdmin.AcceptanceCase
  alias TestExAdmin.{Product}

  hound_session()
  # Start hound session and destroy when tests are run
  setup do
    user = insert_user()
    current_window_handle() |> maximize_window
    {:ok, user: user}
  end

  @tag :integration
  test "create a product", %{ user: user } do
    navigate_to admin_resource_path(Product, :new)

    title_field = find_element(:name, "product[title]")
    price_field = find_element(:name, "product[price]")
    _user_field = find_element(:name, "product[user_id]")

    fill_field title_field, "Test Create"
    fill_field price_field, ".99"
    find_element(:css, "select[name*='product[user_id]']")
    |> find_all_within_element(:css, "option")
    |> Enum.find(fn(x) -> attribute_value(x, "value") == "#{user.id}" end)
    |> click

    click(find_element(:name, "commit"))

    assert visible_text(find_element(:class, "td-title")) == "Test Create"
    assert visible_text(find_element(:class, "td-price")) == "0.99"
    assert visible_text(find_element(:class, "td-user")) == user.name
  end

  @tag :integration
  test "validate product creation" do
    navigate_to admin_resource_path(Product, :new)
    click(find_element(:name, "commit"))

    title_wrapper = find_element(:css, "#product_title_input")
    price_wrapper = find_element(:css, "#product_price_input")
    assert visible_text(title_wrapper) == "Title*\ncan't be blank"
    assert visible_text(price_wrapper) == "Price*\ncan't be blank"
  end
end
