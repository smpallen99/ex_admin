defmodule ExAdmin.Query do
  import Ecto.Query, except: [count: 1]
  require Logger
  alias ExAdmin.Helpers
  
  def run_query(resource_model, repo, action, id, query_opts) do
    Logger.warn "run_query: resource_model: #{inspect resource_model}, action: #{action}, id: #{inspect id}, query_opts: #{inspect query_opts}"
    resource_model
    |> build_query(query_opts, action, id)
    |> paginate(repo, action, id)
  end

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
  defp paginate(query, repo, :nested, params) do 
    Logger.warn "paginate nested params: #{inspect params}, query: #{inspect query}"
    apply repo, get_method(:nested), [query]
  end
  defp paginate(query, repo, action, _) do 
    apply repo, get_method(action), [query]
  end

  defp filter(query, params) do
    q = Keyword.get(params, :q)
    if q do
      filters = Map.to_list(q) |> Enum.filter(&(elem(&1,1) != "")) |> Enum.map(&({Atom.to_string(elem(&1, 0)), elem(&1, 1)}))
      string_filters(filters)
      |> integer_filters(filters)
      |> date_filters(filters)
      |> build_filter_query(query)
    else
      query
    end
  end

  defp string_filters(filters) do
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_contains$/)), &({String.replace(elem(&1, 0), "_contains", ""), elem(&1, 1)}))
    |> Enum.reduce("", fn({k,v}, acc) -> acc <> ~s| and like(c.#{k}, "%#{v}%")| end)
  end

  defp integer_filters(builder, filters) do
    builder
    |> build_integer_filters(filters, :eq)
    |> build_integer_filters(filters, :lt)
    |> build_integer_filters(filters, :gt)
  end

  defp date_filters(builder, filters) do
    builder 
    |> build_date_filters(filters, :gte)
    |> build_date_filters(filters, :lte)
  end

  defp build_integer_filters(builder, filters, condition) do
    cond_str = condition_to_string condition
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) -> acc <> ~s| and c.#{k} #{cond_str} #{v}| end)
  end

  defp build_date_filters(builder, filters, condition) do
    cond_str = condition_to_string condition

    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{condition}$/)), &({String.replace(elem(&1, 0), "_#{condition}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) -> acc <> ~s| and fragment("? #{cond_str} '?'", c.#{k}, \"#{cast_date_time(v)}\")| end)
  end

  defp condition_to_string(condition) do
    case condition do
      :gte -> ">="
      :lte -> "<="
      :gt -> ">"
      :eq -> "=="
      :lt -> "<"
    end
  end

  defp cast_date_time(value) do
    {:ok, dt} = Ecto.Date.cast(value)
    Ecto.Date.to_string dt
  end

  defp build_filter_query("", query), do: query
  defp build_filter_query(builder, query) do
    builder = String.replace(builder, ~r/^ and /, "")
    "where(query, [c], #{builder})"
    |> Code.eval_string([query: query], __ENV__)
    |> elem(0)
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

  defp get_association(model, field) do
    field = String.to_atom(field)
    [assoc, _] = model.__schema__(:association, field) |> Map.get(:through)
    model.__schema__(:association, assoc)
  end

  defp build_preloads(query, opts, action, _id) do
    preloads = case {query.preloads, get_from(opts, action, :preload)} do
      {[], []}         -> get_from_all(opts, :preload)
      {[_|_] = qry, _} -> qry
      {_, [_|_] = act} -> act
    end
    preload(query, ^preloads)
  end

  defp build_order_bys(query, opts, :index, params) do
    case Keyword.get(params, :order, nil) do
      nil -> build_default_order_bys(query, opts, :index, params)
      order -> 
        case Helpers.get_sort_order(order) do
          nil -> build_default_order_bys(query, opts, :index, params)
          {name, sort_order} -> 
            name_atom = String.to_atom name
            if sort_order == "desc" do
              order_by query, [c], [desc: field(c, ^name_atom)]
            else
              order_by query, [c], [asc: field(c, ^name_atom)]
            end

        end
    end
  end
  defp build_order_bys(query, _, _, _), do: query

  defp build_default_order_bys(query, _opts, :index, _params) do
    case query.order_bys do
      [] -> order_by(query, [c], [desc: c.id])
      _ -> query
    end
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
