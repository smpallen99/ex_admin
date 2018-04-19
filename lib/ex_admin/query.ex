defmodule ExAdmin.Query do
  @moduledoc false

  import Ecto.Query, except: [count: 1]
  require Logger
  # alias ExAdmin.Helpers
  import ExQueb
  alias ExAdmin.Schema

  @doc false
  def get_scope(scopes, nil) do
    (Enum.find(scopes, fn {_, v} -> v[:default] == true end) || hd(scopes)) |> elem(0)
  end

  def get_scope(_scopes, scope), do: to_atom(scope)

  @doc false
  def run_query(resource_model, _repo, defn, action, id, query_opts) do
    resource_model
    |> build_query(query_opts, action, id, defn)
  end

  def execute_query(query, repo, action, id) do
    paginate(query, repo, action, id)
  end

  @doc false
  def run_query_counts(resource_model, repo, defn, _action, params, _query_opts) do
    for {name, _opts} <- defn.scopes do
      resource_model
      |> scope_where(defn.scopes, name)
      |> ExQueb.filter(params)
      |> count_q(repo, name)
    end
  end

  @doc false
  def count([]), do: 0

  def count(resources) when is_list(resources) do
    repo = Application.get_env(:ex_admin, :repo)
    hd(resources).__struct__ |> select([r], count(r.id)) |> repo.one!
  end

  defp paginate(query, repo, :index, params) do
    query
    |> filter(params)
    |> repo.paginate(params)
  end

  defp paginate(query, repo, :csv, params) do
    apply(repo, get_method(:csv), [query |> filter(params)])
  end

  defp paginate(query, repo, :nested, _params) do
    apply(repo, get_method(:nested), [query])
  end

  defp paginate(query, repo, action, _) do
    apply(repo, get_method(action), [query])
  end

  defp get_method(:index), do: :all
  defp get_method(:csv), do: :all
  defp get_method(:nested), do: :all
  defp get_method(_), do: :one

  defp build_query(%Ecto.Query{} = query, opts, action, id, defn) do
    id = id || []

    build_preloads(query, opts, action, id)
    |> build_order_bys(opts, action, id)
    |> build_wheres(opts, action, id, defn)
  end

  defp build_query(resource_model, opts, action, id, defn) do
    case get_from(opts, action, :query) do
      [] ->
        from(r in resource_model)
        |> build_query(opts, action, id, defn)

      query ->
        build_query(query, opts, action, id, defn)
    end
  end

  defp count_q(query, repo, name) do
    count =
      select(query, [p], count(p.id))
      |> repo.one!

    {name, count}
  end

  defp build_preloads(query, opts, action, _id) do
    preloads =
      case {query.preloads, get_from(opts, action, :preload)} do
        {[], []} -> get_from_all(opts, :preload)
        {[_ | _] = qry, _} -> qry
        {_, [_ | _] = act} -> act
      end

    preload(query, ^preloads)
  end

  defp scope_where(query, [], _scope), do: query

  defp scope_where(query, scopes, scope) do
    case get_scope(scopes, scope) do
      :all ->
        query

      other ->
        case scopes[other][:fun] do
          nil ->
            where(query, [p], field(p, ^other))

          {module, fun} ->
            apply(module, fun, [query])
        end
    end
  end

  defp build_wheres(query, _opts, action, id, defn) when action in [:index, :csv] do
    case defn.scopes do
      nil ->
        query

      [] ->
        query

      scopes ->
        scope_where(query, scopes, get_scope(scopes, id[:scope]))
    end
  end

  defp build_wheres(query, _, _action, id, _defn) do
    {id, key} =
      case Schema.primary_key(query) do
        nil ->
          {:id, id}

        key ->
          if Schema.type(query, key) == :string, do: {"#{id}", key}, else: {id, key}
      end

    where(query, [c], field(c, ^key) == ^id)
  end

  defp get_from_all(opts, key, default \\ []), do: get_from(opts, :all, key, default)

  defp get_from(opts, from, key, default \\ [])
  defp get_from(nil, _from, _key, default), do: default

  defp get_from(opts, from, key, default) do
    Map.get(opts, from, [])
    |> Keyword.get(key, default)
  end

  def to_atom(value) when is_atom(value), do: value
  def to_atom(value) when is_binary(value), do: String.to_atom(value)
end
