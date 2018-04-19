defmodule ExAdmin.EctoFormMapper do
  use TestExAdmin.ConnCase
  use ExUnit.Case
  alias ExAdmin.EctoFormMapper, as: Params

  test "build for checkboxes" do
    role = insert_role
    role2 = insert_role
    params = %{roles: %{"#{role.id}": "on"}}
    expected_ids = ["#{role.id}"]
    ids = Params.build_for_checkboxes(params[:roles])
    expected_loaded = [role]
    assert ids == expected_ids
  end

  test "checkboxes with none selected" do
    params = %{role_ids: [""]}
    ids = Params.build_for_checkboxes(params[:role_ids])
    assert ids == []
  end
end
