defmodule ExAdmin.AssociationController do
  use ExAdmin.Web, :controller
  require Logger

  def update_positions(conn, %{"association_name" => association_name, "positions" => positions} = params) do
    defn = ExAdmin.get_registered_by_controller_route!(params["resource"], conn)
    positions = prepare_positions(defn, positions)

    repo.get!(defn.resource_model, params["id"])
    |> repo.preload(String.to_existing_atom(association_name))
    |> defn.resource_model.changeset(%{association_name => positions})
    |> repo.update!

    conn |> put_status(200) |> json("Ok")
  end


  defp prepare_positions(%{position_column: nil}, positions), do: positions
  defp prepare_positions(%{position_column: position_column}, positions) do
    position_column = to_string(position_column)
    positions 
    |> Enum.map(fn({idx, %{"id" => id, "position" => position}}) ->
      {idx, %{"id" => id, position_column => position}}
    end)
    |> Enum.into(%{})
  end


  defp repo, do: Application.get_env(:ex_admin, :repo)
end