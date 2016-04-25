defmodule ExAdmin.QueryTest do
  use ExUnit.Case
  require Logger


  test "run_query with resource with non default primary key" do
    TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, %{name: "test name", description: "test description"})
    |> TestExAdmin.Repo.insert! 
    query_opts = %{all: [preload: []]}
    res = ExAdmin.Query.run_query(TestExAdmin.Noid,  TestExAdmin.Repo, %TestExAdmin.ExAdmin.Noid{},
      :show, "test name", query_opts)
    assert res.name == "test name"
  end

end
