defmodule ExAdmin.RepoTest do
  use ExUnit.Case
  require Logger

  alias ExAdmin.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
  end

  test "changeset supports different primary key" do
    params = %{name: "test", description: "desc"}
    cs = %ExAdmin.Changeset{changeset: TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, params)}
    res = Repo.insert(cs)
    assert res.name == "test"
    assert res.description == "desc"
  end
end
