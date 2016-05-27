defmodule ExAdmin.RepoTest do
  use ExUnit.Case
  require Logger
  alias ExAdmin.Repo

  defmodule Schema do
    defstruct id: 0, name: nil
  end
  defmodule Schema2 do
    defstruct id: 0, field: nil
  end
  defmodule Cs1 do
    defstruct model: nil, changes: %{}
  end
  defmodule Cs2 do
    defstruct data: nil, changes: %{}
  end

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

  test "sets data for ecto2" do
    cs = %Cs2{data: %Schema{id: 1, name: "test"}}
    cs = Repo.set_cs_data(cs, %{name: "test2"})
    assert cs.data.name == "test2"
  end

  test "sets data for ecto1" do
    cs = %Cs1{model: %Schema{id: 1, name: "test"}}
    cs = Repo.set_cs_data(cs, %{name: "test2"})
    assert cs.model.name == "test2"
  end

  test "set_dependents ecto2" do
    expected = %ExAdmin.RepoTest.Cs2{changes: %{name: "test"},
      data: %ExAdmin.RepoTest.Schema{id: 0, name: nil}}
    list = [{"fields", %Cs2{changes: %{field: "f1"}, data: %Schema2{}}}]
    cs = %Cs2{data: %Schema{}, changes: %{name: "test"}}
    cs = Repo.set_dependents(cs, list)
    assert cs == expected
  end

  test "set_dependents ecto1" do
    expected = %ExAdmin.RepoTest.Cs1{changes: %{name: "test"},
      model: %ExAdmin.RepoTest.Schema{id: 0, name: nil}}
    list = [{"fields", %Cs1{changes: %{field: "f1"}, model: %Schema2{}}}]
    cs = %Cs1{model: %Schema{}, changes: %{name: "test"}}
    cs = Repo.set_dependents(cs, list)
    assert cs == expected
  end

  test "set_changeset_collection ecto2" do
    cs = %ExAdmin.Changeset{changeset: %Cs2{data: %Schema{}}}
    fields = [{"id", 1}, {"name", "T"}]
    cs = Repo.set_changeset_collection(fields, cs)
    assert cs.changeset.data.id == 1
    assert cs.changeset.data.name == "T"
  end

  test "set_changeset_collection ecto1" do
    cs = %ExAdmin.Changeset{changeset: %Cs1{model: %Schema{}}}
    fields = [{"id", 2}, {"name", "TT"}]
    cs = Repo.set_changeset_collection(fields, cs)
    assert cs.changeset.model.id == 2
    assert cs.changeset.model.name == "TT"
  end
end
