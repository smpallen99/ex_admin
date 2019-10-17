defmodule ExAdmin.EctoFormMappers do
  def checkboxes_to_ids(params) do
    cond do
      params == [""] -> []
      true -> filter_checkboxes(params)
    end
  end

  defp filter_checkboxes(params) do
    # convert to array of id's
    params
    |> Enum.filter(fn x ->
      elem(x, 1) == "on"
    end)
    |> Enum.map(fn
      {item, _} when is_atom(item) -> Atom.to_string(item)
      {item, _} -> item
    end)
  end
end
