defmodule ExAdmin.QueryTest do
  use ExUnit.Case
  require Logger
  import TestExAdmin.TestHelpers


  test "run_query with resource with non default primary key" do
    insert_noid name: "query1"
    query_opts = %{all: [preload: []]}
    res = ExAdmin.Query.run_query(TestExAdmin.Noid,  TestExAdmin.Repo, %TestExAdmin.ExAdmin.Noid{},
      :show, "query1", query_opts)
    assert res.name == "query1"
  end

end
