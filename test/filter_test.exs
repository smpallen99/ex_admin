defmodule ExAdmin.FilterTest do
  use ExUnit.Case, async: true
  alias ExAdmin.Filter

  ############
  # filters

  test "filters" do
    defn = %TestExAdmin.ExAdmin.User{}
    assert Filter.fields(defn) == [name: :string, email: :string]
  end
  test "filters except" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[except: [:name, :email]]]}
    assert Filter.fields(defn) == [active: :boolean]
  end
  test "filters all" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    assert Filter.fields(defn) == [name: :string, email: :string, active: :boolean]
  end
  test "filters only" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[only: [:name, :active]]]}
    assert Filter.fields(defn) == [name: :string, active: :boolean]
  end
  test "filters only field_label" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[only: [:name, :email], labels: [email: "EMail Address"]]]}
    assert Filter.fields(defn) == [name: :string, email: :string]
  end
  test "filters except field_label" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[except: [:active], labels: [email: "EMail Address"]]]}
    assert Filter.fields(defn) == [name: :string, email: :string]
  end
  test "filters default field_label" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[labels: [email: "EMail Address"]]]}
    assert Filter.fields(defn) == [name: :string, email: :string, active: :boolean]
  end

  test "filters except several fields" do
    defn = %TestExAdmin.ExAdmin.Noprimary{index_filters: [[except: [:inserted_at, :updated_at]]]}
    assert Filter.fields(defn) == [index: :integer, name: :string, description: :string]
  end

  ############
  # filters

  test "filter_label default" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    assert Filter.field_label(:name, defn) == "Name"
    assert Filter.field_label(:email, defn) == "Email"
  end
  test "filter_label label" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [[labels: [email: "EMail Address", name: "Full Name"]]]}
    assert Filter.field_label(:name, defn) == "Full Name"
    assert Filter.field_label(:email, defn) == "EMail Address"
  end
end
