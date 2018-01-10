defmodule ExAdmin.ThemeTest do
  use ExUnit.Case
  alias ExAdmin.Theme.{ActiveAdmin, AdminLte2}

  ###############
  # AdminLte2 Theme

  test "AdminLte2 wrap_item_type boolean not required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(:boolean, :name, "simple_name", contents, "", false)
    label = Floki.find(res, "div div.checkbox label")
    refute label == []
    assert Floki.text(label) =~ "Name"
  end

  test "AdminLte2 wrap_item_type not required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "", false)
    assert_label(res, "simple_name")
    refute_required(res)
    refute_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type required no error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "", true)
    assert_label(res, "simple_name")
    assert_required(res)
    refute_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type not required error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "error ", false)
    assert_label(res, "simple_name")
    refute_required(res)
    assert_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "AdminLte2 wrap_item_type required error" do
    contents = fn _ -> "" end
    res = AdminLte2.wrap_item_type(nil, :name, "simple_name", contents, "error ", true)
    assert_label(res, "simple_name")
    assert_required(res)
    assert_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  ###############
  # ActiveAdmin Theme

  test "ActiveAdmin wrap_item_type not required no error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "", false)
    assert_label(res, "simple_name")
    refute_required(res)
    refute_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type required no error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "", true)
    assert_label(res, "simple_name")
    assert_required(res)
    refute_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type not required error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "error ", false)
    assert_label(res, "simple_name")
    refute_required(res)
    assert_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  test "ActiveAdmin wrap_item_type required error" do
    contents = fn _ -> "" end
    res = ActiveAdmin.wrap_item_type(nil, :name, "simple_name", contents, "error ", true)
    assert_label(res, "simple_name")
    assert_required(res)
    assert_error(res)
    refute Floki.find(res, "div.col-sm-10") == []
  end

  #############
  # Helpers

  def assert_error(html) do
    error = Floki.find(html, "div.has-error")
    refute error == []
  end

  def refute_error(html) do
    error = Floki.find(html, "div.has-error")
    assert error == []
  end

  def assert_label(html, for_name) do
    label = Floki.find(html, "label.control-label")
    refute label == []
    assert Floki.attribute(label, "for") == [for_name]
  end

  def refute_required(html) do
    assert Floki.find(html, "abbr") == []
  end

  def assert_required(html) do
    abbr = Floki.find(html, "abbr.required")
    refute abbr == []
    assert Floki.text(abbr) == "*"
  end
end
