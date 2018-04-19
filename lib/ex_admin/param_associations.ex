defmodule ExAdmin.ParamsAssociations do
  @moduledoc false
  require Logger

  def load_associations(params, model_name, model, delete_association \\ true) do
    case Map.has_key?(params, model_name) do
      true ->
        Map.put(
          params,
          model_name,
          do_load_associations(params[model_name], model, delete_association)
        )

      false ->
        params
    end
  end

  defp do_load_associations(params, _model, _delete_associations) do
    Enum.reduce(Map.keys(params), params, fn key, p ->
      key_as_string = Atom.to_string(key)

      cond do
        String.ends_with?(key_as_string, "attributes") ->
          new_key =
            String.replace_suffix(key_as_string, "_attributes", "")
            |> String.to_atom()

          Map.delete(p, key)
          |> Map.put(new_key, params[key])

        String.ends_with?(key_as_string, "_ids") ->
          new_key =
            String.replace_suffix(key_as_string, "_ids", "s")
            |> String.to_atom()

          value = build_for_checkboxes(params[key])

          Map.delete(p, key)
          |> Map.put(new_key, value)

        true ->
          p
      end
    end)
  end

  def build_for_checkboxes([]) do
    []
  end

  def build_for_checkboxes([""]) do
    []
  end

  def build_for_checkboxes(params) do
    # convert to array of id's
    Enum.filter_map(
      params,
      fn x ->
        elem(x, 1) == "on"
      end,
      fn x ->
        Atom.to_string(elem(x, 0))
      end
    )
  end
end
