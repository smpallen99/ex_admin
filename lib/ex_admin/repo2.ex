defmodule ExAdmin.Repo2 do

  def insert(changeset) do
    repo.insert(changeset.changeset)
    # |> insert_associations(changeset)
  end

  def update(changeset) do
    repo.update changeset.changeset
  end

  defp repo, do: Application.get_env(:ex_admin, :repo)
end
