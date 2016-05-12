defmodule ExAdmin.Changeset2 do

  defstruct changeset: nil, params: %{}, defn: nil

  def changeset(resource, defn, params) do
    cs = defn.resource_model.changeset(resource, params)
    |> cast_associations(params)
    %__MODULE__{changeset: cs, params: params, defn: defn}
  end

  defp cast_associations(changeset, params) do
    changeset.data.__struct__.__schema__(:associations)
    |> Enum.reduce(changeset, fn assoc, acc ->
      cast_assoc(acc, assoc, params[to_string(assoc)])
    end)
  end

  defp cast_assoc(changeset, _assoc, nil), do: changeset
  defp cast_assoc(changeset, assoc, _) do
    Ecto.Changeset.cast_assoc(changeset, assoc)
  end

end
