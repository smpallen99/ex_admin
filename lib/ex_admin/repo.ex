defmodule ExAdmin.Repo do
  @moduledoc false
  require Logger
  alias ExAdmin.Utils
  alias ExAdmin.Helpers
  alias ExAdmin.Changeset
  import Ecto.Query
  require IEx

  def repo, do: Application.get_env(:ex_admin, :repo)

  def changeset(fun, resource, nil), do: changeset(fun, resource, %{})
  def changeset(fun, resource, params) do
    %ExAdmin.Changeset{}
    |> changeset(fun, resource, params)
    |> changeset_attributes_for(resource, params)
    |> changeset_collection(resource, params)
  end

  def changeset(%Changeset{} = changeset, fun, resource, nil),
    do: changeset(changeset, fun, resource, %{})
  def changeset(%Changeset{} = changeset, fun, resource, params) do
    cs = fun.(resource, params)
    Changeset.update(changeset, valid?: cs.valid?, changeset: cs, errors: cs.errors)
  end

  def changeset_attributes_for(%Changeset{} = changeset, resource, params) do
    {new_changeset, fields} =
    Enum.reduce insert_or_update_attributes_for(resource, params), {changeset, []},
      fn({cs, fun, field}, {acc, fields}) ->
        cs = ExAdmin.Changeset.set_data cs, params
        {Changeset.update(acc, valid?: cs.valid?, dependents: {cs, fun}, errors: cs.errors), fields ++ [{field, cs}]}
      end
    struct(new_changeset, changeset: set_dependents(new_changeset.changeset, fields))
  end

  def changeset_collection(%Changeset{} = changeset, resource, params) do
    {new_changeset, fields} =
    Enum.reduce insert_or_update_collection(resource, params), {changeset, []},
      fn({coll, fun, field}, {acc, fields}) ->
        {Changeset.update(acc, dependents: {nil, fun}), fields ++ [{field, coll}]}
      end
    set_changeset_collection fields, new_changeset
  end

  def set_changeset_collection(fields, %{changeset: %{data: _data}} = changeset) do
    data = Enum.reduce fields, changeset.changeset.data, fn({k, v}, acc) ->
      struct(acc, [{String.to_atom(k), v}])
    end
    struct(changeset, changeset: struct(changeset.changeset, data: data))
  end
  def set_changeset_collection(fields, %{changeset: %{model: _data}} = changeset) do
    data = Enum.reduce fields, changeset.changeset.model, fn({k, v}, acc) ->
      struct(acc, [{String.to_atom(k), v}])
    end
    struct(changeset, changeset: struct(changeset.changeset, model: data))
  end

  def set_dependents(changeset, list) do
    fields = Helpers.group_by(list, fn({key, _val}) -> key end)
    |> Enum.map(fn({k,v}) ->
      {String.to_atom(k), set_dependents_list(v)}
    end)

    ExAdmin.Changeset.set_data changeset, fields
  end

  defp set_dependents_list([]), do: []
  defp set_dependents_list([{_, %{data: _}} | _] = map) do
    for %{data: data, changes: changes} <- Keyword.values(map) do
      struct(data, Map.to_list(changes))
    end
  end
  defp set_dependents_list([{_, %{model: _}} | _] = map) do
    for %{model: data, changes: changes} <- Keyword.values(map) do
      struct(data, Map.to_list(changes))
    end
  end

  def update(%Changeset{} = changeset) do
    case repo.update changeset.changeset do
      {:ok, resource} ->
        for {cs, fun} <- changeset.dependents do
          if cs do
            dependent = if Map.get(cs.params, "id") do
              repo.update!(cs)
            else
              repo.insert!(cs)
            end
            fun.(resource, dependent)
          else
            fun.(resource)
          end
        end
        resource
      error -> error
    end
  end

  def update(resource, params) do
    insert_or_update_collection(resource, params)
    |> insert_or_update_attributes_for(params)
    |> struct(Map.to_list(params))
    |> repo.update
  end

  def insert(%ExAdmin.Changeset{} = changeset) do
    case repo.insert changeset.changeset do
      {:ok, resource} ->
        case ExAdmin.Schema.primary_key(resource) do
          nil -> resource
          key ->
            resource = repo.get(resource.__struct__, Map.get(resource, key))

            for {cs, fun} <- changeset.dependents do
              if cs do
                fun.(resource, repo.insert!(cs))
              else
                fun.(resource)
              end
            end
            resource
        end
      error -> error
    end
  end

  def insert(resource, params) do
    repo.insert!(struct(resource, params))
    |> insert_or_update_collection(params)
    |> insert_or_update_attributes_for(params)
  end

  def delete(resource, _params) do
    repo.delete resource
  end

  def get_attrs_list(params) do
    Enum.map(Map.keys(params), &(Atom.to_string &1))
    |> Enum.reduce([], fn(x, acc) ->
      if String.ends_with?(x, "_attributes") do
        atom = String.to_atom(x)
        acc ++ [{String.replace(x, "_attributes", ""), build_params_list(params[atom])}]
      else
        acc
      end
    end)
  end

  def get_collections(params) do
    Enum.reduce params, [], fn({key, val}, acc) ->
      key_str = Atom.to_string key
      cond do
        is_list(val) and String.ends_with?(key_str, "ids") ->
          val = Enum.filter(val, &(&1 != ""))
          ids = Enum.map(val, &(String.to_integer(&1)))
          [{String.replace(key_str, "_id", "") |> String.to_atom, ids} | acc]
        is_map(val) and String.ends_with?(key_str, "ids") ->
          ids = Map.keys(val) |> Enum.map(&(Atom.to_string(&1) |> String.to_integer))
          [{String.replace(key_str, "_id", "") |> String.to_atom, ids} | acc]
        true ->
          acc
      end
    end
  end

  def insert_or_update_collection(resource, params) do
    get_collections(params)
    |> Enum.reduce([], &(&2 ++ [do_collection(resource, &1)]))
  end

  def do_collection(resource, {assoc, ids}) do
    {assoc_model, join_model} = get_assoc_model resource, assoc
    assoc_instance = assoc_model.__struct__
    selected_collection = for id <- ids, do: struct(assoc_instance, id: id)

    fun = fn(resource) ->
      id = resource.id
      resource = repo.one from c in resource.__struct__, where: ^id == c.id, preload: [^assoc]
      existing_ids = for ass <- Helpers.get_resource_field2(resource, assoc), do: ass.id

      # removes
      for id <- Utils.not_in(existing_ids, ids) do
        new_model = struct(assoc_instance, id: id)
        repo.delete_all get_join_model_instance(resource, assoc, join_model, new_model)
      end

      # insert adds
      for id <- Utils.not_in(ids, existing_ids) do
        new_model = struct(assoc_instance, id: id)
        repo.insert! join_model_instance(resource, assoc, join_model, new_model)
      end
    end
    {selected_collection, fun, Atom.to_string(assoc)}
  end

  def insert_or_update_attributes_for(resource, params) do

    res = get_attrs_list(params)
    |> Enum.reduce([], fn({model, items}, acc1) ->
      List.keysort(items, 0)
      |> Enum.with_index
      |> Enum.reduce(acc1, fn({{id, item}, inx}, acc2) ->
        acc2 ++ [do_attributes_for(resource, model, id, item, inx)]
      end)
    end)
    res
  end

  def do_attributes_for(resource, model, id, params, inx) when id > 100000000000 or id == nil do
    {assoc_model, join_model} = get_assoc_model resource, model

    cs = assoc_model.changeset(assoc_model.__struct__, params)
    |> attributes_for_translate_errors(resource, model, inx)

    fun = fn(resource, new_model) ->
      # repo.insert! join_model_instance(resource, model, join_model, new_model)
      res = join_model_instance(resource, model, join_model, new_model)

      repo.insert! res
    end

    {cs, fun, model}
  end


  # handle the case to destroy the association

  def do_attributes_for(resource, model, _id, %{_destroy: "1"} = params, inx) do
    {assoc_model, join_model} = get_assoc_model resource, model

    assoc_resource = repo.get assoc_model, params[:id]

    cs = assoc_model.changeset(assoc_resource, params)
    |> attributes_for_translate_errors(resource, model, inx)

    fun = fn(resource, new_model) ->
      get_join_model_instance(resource, model, join_model, new_model)
      |> repo.delete_all
    end

    {cs, fun, model}
  end

  # Handles update the attributes for an nested attributes
  # For example, when resource is an instance of Contact
  # model = "phone_numbers", assoc_model = PhoneNumber
  #
  def do_attributes_for(resource, model, _id, params, inx) do
    {assoc_model, _} = get_assoc_model resource, model
    require IEx
    IEx.pry
    assoc_resource = repo.get assoc_model, params[:id]

    cs = assoc_model.changeset(assoc_resource, params)
    |> attributes_for_translate_errors(resource, model, inx)

    fun = fn(_, _) -> nil end

    {cs, fun, model}
  end

  def attributes_for_translate_errors(%{errors: errors} = cs, resource, model, inx) do
    errors = for {name, val} <- errors do
      {"#{Helpers.model_name(resource)}[#{model}_attributes][#{inx}][#{name}]", val}
    end
    struct(cs, errors: errors)
  end

  def join_model_instance(resource, has_many_atom, join_model, new_model) do
    res_model = resource.__struct__
    # get the join model atom
    join_table_name = get_assoc_join_name(resource, Utils.to_atom(has_many_atom))
res =     struct(join_model.__struct__, [
      {res_model.__schema__(:association, join_table_name).related_key, resource.id},
      {new_model.__struct__.__schema__(:association, join_table_name).related_key, new_model.id}
    ])
res
  end

  def get_join_model_instance(resource, has_many_atom, join_model, new_model) do
    res_model = resource.__struct__

    # get the join model atom
    join_table_name = get_assoc_join_name(resource, Utils.to_atom(has_many_atom))

    field1 = res_model.__schema__(:association, join_table_name).related_key
    field2 = new_model.__struct__.__schema__(:association, join_table_name).related_key

    "from c in #{join_model}, where: c.#{field1} == #{resource.id} and " <>
      "c.#{field2} == #{new_model.id}"
    |> Code.eval_string([], __ENV__)
    |> elem(0)
    #|> repo.one
  end

  def get_assoc_join_name(resource, field) do
    res_model = resource.__struct__
    case res_model.__schema__(:association, field) do
      %{through: [first, _]} -> first
      _ -> {:error, :notfound}
    end
  end

  def get_assoc_join_fields(resource, field) when is_binary(field) do
    get_assoc_join_fields(resource, String.to_atom(field))
  end
  def get_assoc_join_fields(resource, field) do
    res_model = resource.__struct__
    case res_model.__schema__(:association, field) do
      %{through: [first, _]} ->
        # assoc_model =  res_model.__schema__(:association, first).assoc_key
        {:ok, {
          res_model.__schema__(:association, first).related_key,
          res_model.__schema__(:association, first).related.related_key,
        }}
      _ ->
        {:error, :notfound}
    end
  end

  def get_assoc_join_model(resource, field) when is_binary(field) do
    get_assoc_join_model(resource, String.to_atom(field))
  end
  def get_assoc_join_model(resource, field) do
    res_model = resource.__struct__
    case res_model.__schema__(:association, field) do
      %{through: [first, second]} ->
        {:ok, {res_model.__schema__(:association, first).related, second}}
      _ ->
        {:error, :notfound}
    end
  end

  def get_assoc_model(resource, field) when is_binary(field) do
    get_assoc_model resource, String.to_atom(field)
  end
  def get_assoc_model(resource, field) do
    case get_assoc_join_model(resource, field) do
      {:ok, {assoc, second}} ->
        # IEx.pry
        {assoc.__schema__(:association, second).related, assoc}
      error ->
        error
    end
  end

  defp build_params_list(params_map) do
    res = params_map
    |> Map.to_list
    |> Enum.map(fn({k, v}) ->
      {k |> Atom.to_string |> String.to_integer, v}
    end)
    |> Enum.sort(&(elem(&1, 0) < elem(&2, 0)))
    res
  end

end
