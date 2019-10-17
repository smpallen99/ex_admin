defmodule ExAdmin.ThemeTest do
  use ExUnit.Case
  alias ExAdmin.Theme.{ActiveAdmin, AdminLte2}

  ###############
  # AdminLte2 Theme

  test "AdminLte2 wrap_item_type boolean not required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(:boolean, :name, "simple_name", contents, "", false)
    label = get_clean_html(res) |> Floki.find("div div.checkbox label")
    refute label == []
    assert Floki.text(label) =~ "Name"
  end

  test "AdminLte2 wrap_item_type not required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "", false)
    assert_label(res, "simple_name")
    refute_required(res)
    refute_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "", true)
    assert_label(res, "simple_name")
    assert_required(res)
    refute_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type not required error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "error ", false)
    assert_label(res, "simple_name")
    refute_required(res)
    assert_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type required error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "error ", true)
    assert_label(res, "simple_name")
    assert_required(res)
    assert_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  ###############
  # ActiveAdmin Theme

  test "ActiveAdmin wrap_item_type not required no error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "", false)
    assert_label(res, "simple_name")
    refute_required(res)
    refute_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type required no error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "", true)
    assert_label(res, "simple_name")
    assert_required(res)
    refute_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type not required error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "error ", false)
    assert_label(res, "simple_name")
    refute_required(res)
    assert_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type required error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "error ", true)
    assert_label(res, "simple_name")
    assert_required(res)
    assert_error(res)
    refute get_clean_html(res) |> Floki.find("div.col-sm-10") == []
  end

  #############
  # Helpers

  def assert_error(html) do
    error =
      html
      |> get_clean_html()
      |> Floki.find("div.has-error")

    refute error == []
  end

  def refute_error(html) do
    error =
      html
      |> get_clean_html()
      |> Floki.find("div.has-error")

    assert error == []
  end

  def assert_label(html, for_name) do
    label =
      html
      |> get_clean_html()
      |> Floki.find("label.control-label")

    refute label == []
    assert Floki.attribute(label, "for") == [for_name]
  end

  def refute_required(html) do
    assert html
           |> get_clean_html()
           |> Floki.find("abbr") == []
  end

  def assert_required(html) do
    abbr =
      html
      |> get_clean_html()
      |> Floki.find("abbr.required")

    refute abbr == []
    assert Floki.text(abbr) == "*"
  end

  def get_clean_html(html) do
    html
    |> Phoenix.HTML.safe_to_string()
    |> HtmlEntities.decode()
  end
end
