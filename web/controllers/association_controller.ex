defmodule ExAdmin.AssociationController do
  @moduledoc false
  use ExAdmin.Web, :controller
  require Logger

  def action(conn, _options) do
    defn = ExAdmin.get_registered_by_controller_route!(conn.params["resource"], conn)
    resource = repo.get!(defn.resource_model, conn.params["id"])
    apply(__MODULE__, action_name(conn), [conn, defn, resource, conn.params])
  end

  def update_positions(conn, defn, resource, %{"association_name" => association_name, "positions" => positions} = params) do
    positions = prepare_positions(defn, positions)
    association_name = String.to_existing_atom(association_name)

    resource
    |> repo.preload(association_name)
    |> changeset(association_name, positions)
    |> repo.update!

    conn |> put_status(200) |> json("Ok")
  end

  def index(conn, defn, resource, %{"association_name" => association_name} = params) do
    defn_assoc = ExAdmin.get_registered_by_controller_route!(association_name, conn)
    association_name = String.to_existing_atom(association_name)

    current_assoc_ids = resource
    |> repo.preload(association_name)
    |> Map.get(association_name)
    |> Enum.map(&ExAdmin.Schema.get_id/1)

    assoc_model = defn_assoc.resource_model
    search_query = assoc_model.admin_search_query(params["keywords"])
    page = (from r in search_query, where: not(r.id in ^current_assoc_ids))
    |> repo.paginate(params)

    results = page.entries
    |> Enum.map(fn(r) -> %{id: ExAdmin.Schema.get_id(r), pretty_name: assoc_model.pretty_name(r)} end)

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
      assoc_id = String.to_integer(assoc_id)
      Ecto.build_assoc(resource, through_assoc, %{resource_key => resource_id, assoc_key => assoc_id})
      |> repo.insert!
    end)

    conn
    |> put_flash(:notice, "#{through_assoc} was successfully added")
    |> redirect(to: ExAdmin.Utils.get_route_path(resource, :show, resource_id))
  end

  def toggle_attr(conn, defn, resource, %{"attr_name" => attr_name, "attr_value" => attr_value} = params) do
    attr_name_atom = String.to_existing_atom(attr_name)

    resource = resource
    |> defn.resource_model.changeset(%{attr_name => attr_value})
    |> repo.update!

    render conn, "toggle_attr.js", attr_name: attr_name, attr_value: Map.get(resource, attr_name_atom), id: ExAdmin.Schema.get_id(resource)
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
