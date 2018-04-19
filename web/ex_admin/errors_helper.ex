defmodule ExAdmin.ErrorsHelper do
  @moduledoc """
    The primary purpose of this module is to take nested changeset errors created
    by many_to_many and has many through relationships and change them into a format
    that the forms can use to get the error message from the field name.

    Changes sets such as:
    #Ecto.Changeset<action: nil,
      changes: %{phone_numbers: [#Ecto.Changeset<action: :update, changes: %{},
         errors: [], data: #ContactDemo.PhoneNumber<>, valid?: true>,
          #Ecto.Changeset<action: :update, changes: %{},
            errors: [number: {"can't be blank", []}], data: #ContactDemo.PhoneNumber<>,
            valid?: false>,
          #Ecto.Changeset<action: :insert, changes: %{label: "Primary Phone"},
            errors: [number: {"can't be blank", []}], data: #ContactDemo.PhoneNumber<>,
            valid?: false>]},
      errors: [], data: #ContactDemo.Contact<>, valid?: false>

    need to be walked and each of the error messages needs to be flattened into its
    appropriately namespaced verison.

    To do this we need both the changeset and the schema used to generate the changeset.
    This is required because we need to look at the schema to properly create the neccesary
    form field names. For example, many_to_many association have attributes appended to the
    field name so that we know it is a many to many field.
  """
  def create_errors(changeset, schema) do
    assoc_prefixes = create_prefix_map(schema)
    flatten_errors(changeset, assoc_prefixes)
    |> List.flatten
    |> Enum.filter(fn(x) -> x != nil end)
  end

  defp flatten_errors(errors_array, assoc_prefixes, prefix \\ nil)
  defp flatten_errors(%Ecto.Changeset{changes: changes, errors: errors}, assoc_prefixes, prefix) when errors == [] or is_nil(prefix) do
    changes = Enum.reject(changes, fn({_,v}) -> is_struct(v) end)
    |> Enum.into(%{})
    errors ++ flatten_errors(changes, assoc_prefixes, prefix)
  end

  defp flatten_errors(%Ecto.Changeset{changes: changes, errors: errors}, assoc_prefixes, prefix)  do
    Enum.map(errors, fn({k, v}) -> {concat_atoms(prefix, k), v} end) ++
      flatten_errors(changes, assoc_prefixes, prefix)
  end

  defp flatten_errors(errors_array, assoc_prefixes, prefix) when is_list(errors_array) do
    Enum.with_index(errors_array)
    |> Enum.map(fn({x, i}) ->
     prefix = concat_atoms(prefix, String.to_atom(Integer.to_string(i)))
     flatten_errors(x, assoc_prefixes, prefix)
    end)
  end

  defp flatten_errors(%{__struct__: _struct}, _, _), do: nil

  defp flatten_errors(%{} = errors_map, assoc_prefixes, prefix) do
    Enum.map(errors_map, fn({k, x}) ->
      with k <- if(not is_atom(k), do: String.to_atom(k), else: k),
        k <- if(Keyword.has_key?(assoc_prefixes, k), do: concat_atoms(k, assoc_prefixes[k]), else: k),
        k <- if(prefix != nil, do: concat_atoms(prefix, k), else: k),
      do: flatten_errors(x, assoc_prefixes, k)
    end)
  end

  defp flatten_errors(_, _, _), do: nil

  defp concat_atoms(first, second) do
    "#{first}_#{second}" |> String.to_atom
  end

  defp create_prefix_map(schema) do
    schema.__schema__(:associations)
     |> Enum.map(&(schema.__schema__(:association, &1)))
     |> Enum.map(fn(a) ->
      case a do
        %Ecto.Association.HasThrough{field: field} ->
          { field, :attributes }
        %Ecto.Association.Has{field: field} ->
          { field, :attributes }
        %Ecto.Association.ManyToMany{field: field} ->
          { field, :attributes }
        _ ->
          nil
      end
    end)
  end

  defp is_struct(%{__struct__: _}), do: true
  defp is_struct(_), do: false
end
