defmodule ExAdmin.ParamAssociationsTest do
  use TestExAdmin.ConnCase
  use ExUnit.Case
  require Logger

  import TestExAdmin.TestHelpers
  alias ExAdmin.ParamsAssociations, as: Params

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
  end

  test "has many associations loaded properly" do
    role = insert_role()

    params = %{
      user: %{
        email: "test@example.com",
        name: "Cory",
        products_attributes: %{
          "1481295208513": %{_destroy: "0", price: "13.00", title: "A product title"}
        },
        role_ids: %{"#{role.id}": "on"}
      }
    }

    expected = %{
      user: %{
        email: "test@example.com",
        name: "Cory",
        products: %{"1481295208513": %{_destroy: "0", price: "13.00", title: "A product title"}},
        roles: ["#{role.id}"]
      }
    }

    new_params = Params.load_associations(params, :user, TestExAdmin.User)
    assert new_params == expected
  end

  test "has many associations non choosen" do
    _role = insert_role()

    params = %{
      user: %{email: "test@example.com", name: "Cory", products_attributes: %{}, role_ids: [""]}
    }

    expected = %{user: %{email: "test@example.com", name: "Cory", products: %{}, roles: []}}

    new_params = Params.load_associations(params, :user, TestExAdmin.User)
    assert new_params == expected
  end
end
