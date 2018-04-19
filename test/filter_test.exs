defmodule ExAdmin.FilterTest do
  use ExUnit.Case, async: true
  alias ExAdmin.Filter

  ############
  # filter fields

  test "filters" do
    defn = %TestExAdmin.ExAdmin.User{}
    assert Filter.fields(defn) == [name: :string, email: :string]
  end

  test "filters all" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    assert Filter.fields(defn) == [name: :string, email: :string, active: :boolean]
  end

  test "filters field_label" do
    defn = %TestExAdmin.ExAdmin.User{
      index_filters: [:name, :active, email: [label: "EMail Address"]]
    }

    assert Filter.fields(defn) == [name: :string, active: :boolean, email: :string]
  end

  ############
  # filter options
  describe "filter_options" do
    test "filter_options on empty" do
      defn = %TestExAdmin.ExAdmin.User{index_filters: []}
      assert Filter.filter_options(defn, :name) == nil
      assert Filter.filter_options(defn, :name, :key) == nil
    end

    test "filter_options on atom" do
      defn = %TestExAdmin.ExAdmin.User{index_filters: [:name]}
      assert Filter.filter_options(defn, :name) == []
      assert Filter.filter_options(defn, :name, :key) == nil
    end

    test "filter_options on options" do
      defn = %TestExAdmin.ExAdmin.User{index_filters: [:name, email: [label: "EMail Address"]]}
      assert Filter.filter_options(defn, :email) == [label: "EMail Address"]
      assert Filter.filter_options(defn, :email, :label) == "EMail Address"
      assert Filter.filter_options(defn, :email, :key) == nil
    end
  end

  ############
  # filter labels

  test "filter_label default" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    assert Filter.field_label(:name, defn) == "Name"
    assert Filter.field_label(:email, defn) == "Email"
  end

  test "filter_label label" do
    defn = %TestExAdmin.ExAdmin.User{
      index_filters: [name: [label: "Full Name"], email: [label: "EMail Address"]]
    }

    assert Filter.field_label(:name, defn) == "Full Name"
    assert Filter.field_label(:email, defn) == "EMail Address"
  end
end
