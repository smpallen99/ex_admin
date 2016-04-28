defmodule ExAdmin.Schema do
  @moduledoc """
  Utilities for handling resource schema
  """

  @doc """
  Get the primary key for a resource

  Returns the field name (atom) or nil
  """

  # def primary_key(nil), do: nil
  def primary_key(%Ecto.Query{from: {_, mod}}) do
    primary_key mod    
  end
  def primary_key(module) when is_atom(module) do
    case module.__schema__(:primary_key) do
      [] -> nil
      [key | _] -> key
    end
  end 
  def primary_key(resource) do
    primary_key resource.__struct__
  end
  

  def get_id(resource) do
    Map.get(resource, primary_key(resource))
  end

  def type(%Ecto.Query{from: {_, mod}}, key), do: type(mod, key)
  def type(module, key) when is_atom(module) do
    module.__schema__(:type, key)
  end
  def type(resource, key), do: type(resource.__struct__, key)
end
