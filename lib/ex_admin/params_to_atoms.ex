defmodule ExAdmin.ParamsToAtoms do
  @moduledoc false
  require Logger

  def filter_params(params, schema) do
    params_string_fields_to_integer(params)
    |> params_to_atoms(schema)
  end

  def params_to_atoms(params, schema) do
    list =
      for {key, value} <- params do
        do_params_to_atoms(key, value, schema)
      end

    Enum.into(list, Map.new())
  end

  defp do_params_to_atoms(key, %Plug.Upload{} = value, _) do
    {_to_atom(key), value}
  end

  defp do_params_to_atoms(key, value, schema) when is_map(value) do
    key = _to_atom(key)

    case schema.__schema__(:type, key) do
      {:array, :map} -> {key, Map.values(value)}
      _ -> {key, params_to_atoms(value, schema)}
    end
  end

  defp do_params_to_atoms(key, value, _) do
    {_to_atom(key), value}
  end

  defp _to_atom(key) when is_atom(key), do: key
  defp _to_atom(key), do: String.to_atom(key)

  defp params_string_fields_to_integer(params) do
    list = for {key, value} <- params, do: _replace_integers(key, value)
    Enum.into(list, Map.new())
  end

  @integer_keys ~r/_id$|^id$|page|page_size/

  defp _replace_integers(key, " " <> rest), do: _replace_integers(key, rest)
  defp _replace_integers(key, ""), do: {key, nil}
  defp _replace_integers(key, %Plug.Upload{} = value), do: {key, value}
  defp _replace_integers(key, value) when is_integer(value), do: {key, value}

  defp _replace_integers(key, value) when is_map(value),
    do: {key, params_string_fields_to_integer(value)}

  defp _replace_integers(key, value) when is_atom(key) do
    {_, value} = _replace_integers(Atom.to_string(key), value)
    {key, value}
  end

  defp _replace_integers(key, value) when is_binary(key) do
    if Regex.match?(@integer_keys, key) do
      case {Regex.match?(~r/^[0-9]+$/, value), value} do
        {false, ""} -> {key, nil}
        {true, _} -> {key, String.to_integer(value)}
        _ -> {key, value}
      end
    else
      {key, value}
    end
  end
end
