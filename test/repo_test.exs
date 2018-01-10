defmodule ExAdmin.RepoTest do
  use ExUnit.Case
  require Logger

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
end
