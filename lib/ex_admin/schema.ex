defmodule ExAdmin.Schema do
  @moduledoc false
  def primary_key(%Ecto.Query{from: {_, mod}}) do
    primary_key(mod)
  end

  def primary_key(module) when is_atom(module) do
    case module.__schema__(:primary_key) do
      [] -> nil
      [key | _] -> key
    end
  end

  def primary_key(resource) do
    cond do
      Map.get(resource, :__struct__, false) ->
        primary_key(resource.__struct__)

      true ->
        :id
    end
  end

  def get_id(resource) do
    Map.get(resource, primary_key(resource))
  end

  def type(%Ecto.Query{from: {_, mod}}, key), do: type(mod, key)

  def type(module, key) when is_atom(module) do
    module.__schema__(:type, key)
  end

  def type(resource, key), do: type(resource.__struct__, key)

  def get_intersection_keys(resource, assoc_name) do
    resource_model = resource.__struct__
    %{through: [link1, link2]} = resource_model.__schema__(:association, assoc_name)
    intersection_model = resource |> Ecto.build_assoc(link1) |> Map.get(:__struct__)

    [
      resource_key: resource_model.__schema__(:association, link1).related_key,
      assoc_key: intersection_model.__schema__(:association, link2).owner_key
    ]
  end
end
