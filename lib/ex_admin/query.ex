defmodule ExAdmin.Query do
  @moduledoc false

  import Ecto.Query, except: [count: 1]
  require Logger
  # alias ExAdmin.Helpers
  import ExQueb
  
  @doc false
  def run_query(resource_model, repo, action, id, query_opts) do
    resource_model
    |> build_query(query_opts, action, id)
    |> paginate(repo, action, id)
  end

  @doc false
  def count([]), do: 0
  def count(resources) when is_list(resources) do
    repo = Application.get_env :ex_admin, :repo
    hd(resources).__struct__ |> select([r], count r.id) |> repo.one!
  end

  defp paginate(query, repo, :index, params) do
    query
    |> filter(params)
    |> repo.paginate(params)
  end
  defp paginate(query, repo, :nested, _params) do 
    apply repo, get_method(:nested), [query]
  end
  defp paginate(query, repo, action, _) do 
    apply repo, get_method(action), [query]
  end

  defp get_method(:index), do: :all 
  defp get_method(:csv), do: :all 
  defp get_method(:nested), do: :all 
  defp get_method(_), do: :one

  defp build_query(%Ecto.Query{} = query, opts, action, id) do
    build_preloads(query, opts, action, id)
    |> build_order_bys(opts, action, id)
    |> build_wheres(opts, action, id)
  end
  
  defp build_query(resource_model, opts, action, id) do
    case get_from opts, action, :query do
      [] ->
        (from r in resource_model)
        |> build_query(opts, action, id)
      query -> 
        build_query(query, opts, action, id)
    end
  end

  # defp get_association(model, field) do
  #   field = String.to_atom(field)
  #   [assoc, _] = model.__schema__(:association, field) |> Map.get(:through)
  #   model.__schema__(:association, assoc)
  # end

  defp build_preloads(query, opts, action, _id) do
    preloads = case {query.preloads, get_from(opts, action, :preload)} do
      {[], []}         -> get_from_all(opts, :preload)
      {[_|_] = qry, _} -> qry
      {_, [_|_] = act} -> act
    end
    preload(query, ^preloads)
  end


  defp build_wheres(query, _, action, _) when action in [:index, :csv], do: query
  defp build_wheres(query, _, _action, id) do
    where(query, [c], c.id == ^id)
  end

  defp get_from_all(opts, key, default \\ []), do: get_from(opts, :all, key, default)

  defp get_from(opts, from, key, default \\ [])
  defp get_from(nil, _from, _key, default), do: default
  defp get_from(opts, from, key, default) do
    Map.get(opts, from, [])
    |> Keyword.get(key, default)
  end

end
