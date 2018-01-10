defmodule ExAdminTest.ParamsToAtoms do
  use ExUnit.Case
  require Logger
  alias ExAdmin.ParamsToAtoms, as: Params

  test "filter array of maps" do
    params = %{
      "name" => "Z",
      "addresses" => %{"0" => %{"X" => "_X", "Y" => "_Y"}, "1" => %{"X" => "__X", "Y" => "__Y"}}
    }

    res = Params.filter_params(params, TestExAdmin.Maps)
    assert res[:name] == "Z"
    assert res[:addresses] == [%{"X" => "_X", "Y" => "_Y"}, %{"X" => "__X", "Y" => "__Y"}]
  end
end
