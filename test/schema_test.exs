defmodule ExAdmin.SchemaTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExAdmin.Schema

  test "finds key for default :id" do
    assert Schema.primary_key(%TestExAdmin.Product{}) == :id
  end

  test "finds key for non default key" do
    assert Schema.primary_key(%TestExAdmin.Noid{}) == :name
  end

  test "handles schema without a primary key" do
    refute Schema.primary_key(%TestExAdmin.Noprimary{})
  end

  test "handles query input without a primary key" do
    query = from(c in TestExAdmin.Noid)
    assert Schema.primary_key(query) == :name
  end

  test "get_id for a resource with a non default primary key" do
    assert Schema.get_id(%TestExAdmin.Noid{name: "test"}) == "test"
  end
end
