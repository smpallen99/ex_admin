defmodule ExAdmin.AdminAssociationController do
  @moduledoc false
  use ExAdmin.Web, :controller
  import ExAdmin.Gettext
  require Logger

  def action(conn, _options) do
    defn = get_registered_by_controller_route!(conn, conn.params["resource"])
    resource = repo().get!(defn.resource_model, conn.params["id"])
    #conn = assign(conn, :defn, defn)
    apply(__MODULE__, action_name(conn), [conn, defn, resource, conn.params])
  end

  def update_positions(conn, defn, resource, %{"association_name" => association_name, "positions" => positions}) do
    positions = prepare_positions(defn, positions)
    association_name = String.to_existing_atom(association_name)

    resource
    |> repo().preload(association_name)
    |> changeset(association_name, positions)
    |> repo().update!

    conn |> put_status(200) |> json("Ok")
  end

  def index(conn, _defn, resource, %{"association_name" => association_name} = params) do
    defn_assoc = get_registered_by_controller_route!(conn, association_name)
    assoc_name = String.to_existing_atom(association_name)

    page = ExAdmin.Model.potential_associations_query(resource, defn_assoc.__struct__, assoc_name, params["keywords"])
    |> repo().paginate(params)

    results = page.entries
    |> Enum.map(fn(r) -> %{id: ExAdmin.Schema.get_id(r), pretty_name: ExAdmin.Helpers.display_name(r)} end)

    resp = %{results: results, more: page.page_number < page.total_pages}
    conn |> json(resp)
  end


  def add(conn, defn, resource, %{"association_name" => association_name, "selected_ids" => selected_ids} = params) do
    association_name = String.to_existing_atom(association_name)
    through_assoc = defn.resource_model.__schema__(:association, association_name).through |> hd
    resource_id = ExAdmin.Schema.get_id(resource)

    resource_key = String.to_existing_atom(params["resource_key"])
    assoc_key = String.to_existing_atom(params["assoc_key"])

    selected_ids
    |> Enum.each(fn(assoc_id) ->
      assoc_id = if String.match?(assoc_id, ~r/^\d+$/) do
        String.to_integer(assoc_id)
      else
        assoc_id
      end
      Ecto.build_assoc(resource, through_assoc, %{resource_key => resource_id, assoc_key => assoc_id})
      |> repo().insert!
    end)

    conn
    |> put_flash(:notice, (gettext "%{through_assoc} was successfully added.", through_assoc: through_assoc))
    |> redirect(to: ExAdmin.Utils.admin_resource_path(resource, :show))
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

  defp changeset(struct, assoc_name, positions) do
    struct
    |> Ecto.Changeset.cast(%{assoc_name => positions}, [], [])
    |> Ecto.Changeset.cast_assoc(assoc_name)
  end

  defp repo, do: Application.get_env(:ex_admin, :repo)
end
