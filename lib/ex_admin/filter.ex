Code.ensure_compiled(ExAdmin.Utils)

defmodule ExAdmin.Filter do
  @moduledoc false
  require Logger
  require Ecto.Query
  import ExAdmin.Theme.Helpers
  import ExAdmin.Utils
  import ExAdmin.Gettext
  use Xain

  @integer_options [
    eq: gettext("Equal To"),
    gt: gettext("Greater Than"),
    lt: gettext("Less Than")
  ]
  @string_options [
    contains: gettext("Contains"),
    equals: gettext("Equals"),
    begins_with: gettext("Starts With"),
    ends_with: gettext("End With")
  ]

  def integer_options, do: @integer_options
  def string_options, do: @string_options

  def filter_view(_conn, nil, _defn), do: ""
  def filter_view(_conn, false, _defn), do: ""

  def filter_view(conn, _filters, defn) do
    q = conn.params["q"]
    order = conn.params["order"]
    scope = conn.params["scope"]
    theme_module(conn, Filter).theme_filter_view(conn, defn, q, order, scope)
  end

  def fields(%{index_filters: false}), do: []

  def fields(%{index_filters: filters} = defn) do
    # Either take the filters given by the user, or use the schema's fields.
    # Parse the filters and only return the applicable fields.
    filters =
      filters
      |> case do
        list when is_list(list) and length(list) > 0 -> List.flatten(list)
        _ -> defn.resource_model.__schema__(:fields) -- [:id]
      end
      |> Enum.map(fn
        {field, _options} -> field
        field when is_atom(field) -> field
        _ -> nil
      end)
      |> Enum.filter(&(not is_nil(&1)))

    # Convert the filters to a tuple representing the field name
    # and type.
    Enum.map(filters, fn field ->
      {field, field_type(defn.resource_model, field)}
    end)
  end

  def field_type(model, field) do
    case model.__schema__(:type, field) do
      nil ->
        case model.__schema__(:association, field) do
          %Ecto.Association.BelongsTo{} = belongs_to -> belongs_to
          _ -> nil
        end

      other ->
        other
    end
  end

  def field_label(field, defn) do
    case filter_options(defn, field, :label) do
      nil -> humanize(field)
      label -> label
    end
  end

  def filter_options(defn, field, key \\ nil)

  def filter_options(%{index_filters: filters}, field, key) when is_list(filters) and is_atom(key) do
    filters
    |> List.flatten()
    |> Enum.map(fn
      f when is_atom(f) -> {f, []}
      f when is_tuple(f) -> f
    end)
    |> Keyword.get(field)
    |> case do
      nil ->
        nil

      options ->
        if is_nil(key), do: options, else: Keyword.get(options, key)
    end
  end

  def filter_options(_defn, _field, _key), do: nil

  def filter_resources(field, assoc, defn) do
    import Ecto.Query, only: [from: 2]

    repo = Application.get_env(:ex_admin, :repo)

    case filter_options(defn, field, :order_by) do
      nil -> repo.all(assoc)
      order_by -> repo.all(from(a in assoc, order_by: ^order_by))
    end
  end

  def associations(defn) do
    fields = fields(defn) |> Keyword.keys()

    if Application.get_env(:ex_admin, :disable_association_filters) do
      []
    else
      Enum.reduce(defn.resource_model.__schema__(:associations), [], fn assoc, acc ->
        case defn.resource_model.__schema__(:association, assoc) do
          %Ecto.Association.BelongsTo{owner_key: key} = belongs_to ->
            if key in fields, do: [{assoc, belongs_to} | acc], else: acc

          _ ->
            acc
        end
      end)
    end
  end

  def check_and_build_association(name, q, defn) do
    name_str = Atom.to_string(name)

    if String.match?(name_str, ~r/_id$/) do
      Enum.map(
        defn.resource_model.__schema__(:associations),
        &defn.resource_model.__schema__(:association, &1)
      )
      |> Enum.find(fn assoc ->
        case assoc do
          %Ecto.Association.BelongsTo{owner_key: ^name} ->
            theme_module(Filter).build_field({name, assoc}, q, defn)
            true

          _ ->
            false
        end
      end)
    else
      false
    end
  end

  def integer_selected_name(name, nil), do: "#{name}_eq"

  def integer_selected_name(name, q) do
    Enum.reduce(integer_options(), "#{name}_eq", fn {k, _}, acc ->
      if q["#{name}_#{k}"], do: "#{name}_#{k}", else: acc
    end)
  end

  def string_selected_name(name, nil), do: "#{name}_equals"

  def string_selected_name(name, q) do
    Enum.reduce(string_options(), "#{name}_eq", fn {k, _}, acc ->
      if q["#{name}_#{k}"], do: "#{name}_#{k}", else: acc
    end)
  end

  def get_value(_, nil), do: ""
  def get_value(name, q), do: Map.get(q, name, "")

  def get_integer_value(_, nil), do: ""

  def get_integer_value(name, q) do
    Map.to_list(q)
    |> Enum.find(fn {k, _v} -> String.starts_with?(k, "#{name}") end)
    |> case do
      {_k, v} -> v
      _ -> ""
    end
  end

  def get_string_value(_, nil), do: ""

  def get_string_value(name, q) do
    Map.to_list(q)
    |> Enum.find(fn {k, _v} -> String.starts_with?(k, "#{name}") end)
    |> case do
      {_k, v} -> v
      _ -> ""
    end
  end

  def build_option(text, name, selected_name) do
    selected = if name == selected_name, do: [selected: "selected"], else: []
    option(text, [value: name] ++ selected)
  end
end
