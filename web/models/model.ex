defmodule ExAdmin.Model do
  import Ecto.Query
  import ExAdmin.Repo, only: [repo: 0]

  def potential_associations_query(resource, assoc_model, assoc_name, keywords \\ "") do
    current_assoc_ids = resource
    |> repo.preload(assoc_name)
    |> Map.get(assoc_name)
    |> Enum.map(&ExAdmin.Schema.get_id/1)

    search_query = assoc_model.admin_search_query(keywords)
    (from r in search_query, where: not(r.id in ^current_assoc_ids))
  end
end
