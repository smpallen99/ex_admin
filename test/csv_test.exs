defmodule TestExAdmin.CSV.Columns do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    csv do
      column(:name, fn i -> "Mrs. " <> Map.get(i, :name) end)
      column(:description)
    end
  end
end

defmodule ExAdmin.CSVTest do
  use ExUnit.Case
  alias ExAdmin.CSV
  alias TestExAdmin.Simple

  setup do
    resources = [
      %Simple{id: 1, name: "A", description: "Azz"},
      %Simple{id: 2, name: "B", description: "Bzz"},
      %Simple{id: 3, name: "C", description: "Czz"}
    ]

    {:ok, data: resources}
  end

  test "generates empty default schema" do
    assert CSV.default_schema([]) == []
  end

  test "generates default schema", %{data: data} do
    expected =
      ~w(id name description inserted_at updated_at)a
      |> Enum.map(&%{field: &1, fun: nil})

    assert CSV.default_schema(data) == expected
  end

  test "generates default csv", %{data: data} do
    assert CSV.build_csv(data) ==
             "Id,Name,Description,Inserted At,Updated At\n1,A,Azz,,\n2,B,Bzz,,\n3,C,Czz,,"
  end

  test "custom simple schema", %{data: data} do
    schema = ~w(name description)a |> Enum.map(&%{field: &1, fun: nil})
    assert CSV.build_csv(schema, data, []) == "Name,Description\nA,Azz\nB,Bzz\nC,Czz"
  end

  test "custom schema with fun", %{data: data} do
    schema = [
      %{field: :name, fun: fn i -> "Mr. " <> Map.get(i, :name) end},
      %{field: :description, fun: nil}
    ]

    assert CSV.build_csv(schema, data, []) == "Name,Description\nMr. A,Azz\nMr. B,Bzz\nMr. C,Czz"
  end

  test "custom schema with fun don' humanize", %{data: data} do
    schema = [
      %{field: :name, fun: fn i -> "Mr. " <> Map.get(i, :name) end},
      %{field: :description, fun: nil}
    ]

    assert CSV.build_csv(schema, data, humanize: false) ==
             "name,description\nMr. A,Azz\nMr. B,Bzz\nMr. C,Czz"
  end

  test "list schema", %{data: data} do
    schema = [:name, :description]
    expected = "Name,Description\nA,Azz\nB,Bzz\nC,Czz"
    assert CSV.build_csv(schema, data, []) == expected
  end

  test "generates CSV with column", %{data: data} do
    assert TestExAdmin.CSV.Columns.build_csv(data) ==
             "Name,Description\nMrs. A,Azz\nMrs. B,Bzz\nMrs. C,Czz"
  end

  test "no header", %{data: data} do
    schema = ~w(name description)a |> Enum.map(&%{field: &1, fun: nil})
    assert CSV.build_csv(schema, data, header: false) == "A,Azz\nB,Bzz\nC,Czz"
  end

  test "list with funs", %{data: data} do
    schema = [{:name, fn x -> "Ms. " <> Map.get(x, :name) end}, :description]
    assert CSV.build_csv(schema, data, header: false) == "Ms. A,Azz\nMs. B,Bzz\nMs. C,Czz"
  end
end
