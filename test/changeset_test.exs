defmodule ExAdmin.ChangesetTest do
  use ExUnit.Case

  alias ExAdmin.Changeset

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

  test "sets data for ecto2" do
    cs = %Cs2{data: %Schema{id: 1, name: "test"}}
    cs = Changeset.set_data(cs, %{name: "test2"})
    assert cs.data.name == "test2"
  end

  test "sets data for ecto1" do
    cs = %Cs1{model: %Schema{id: 1, name: "test"}}
    cs = Changeset.set_data(cs, %{name: "test2"})
    assert cs.model.name == "test2"
  end

  test "get data for ecto2" do
    data = Changeset.get_data(%Cs2{data: %Schema{id: 1, name: "T"}})
    assert data.id == 1
    assert data.name == "T"
  end

  test "get data for ecto1" do
    data = Changeset.get_data(%Cs1{model: %Schema{id: 2, name: "TT"}})
    assert data.id == 2
    assert data.name == "TT"
  end
end
