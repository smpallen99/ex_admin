Code.ensure_compiled(ExAdmin.Utils)
defmodule ExAdmin.Filter do
  @moduledoc false
  require Logger
  require Ecto.Query
  import ExAdmin.Utils
  use Xain

  @integer_options [eq: "Equal To", gt: "Greater Than", lt: "Less Than" ]

  def filter_view(_conn, nil, _defn), do: ""
  def filter_view(_conn, false, _defn), do: ""
  def filter_view(conn, _filters, defn) do
    q = conn.params["q"]
    order = conn.params["order"]
    scope = conn.params["scope"] 
    markup do 
      # div "#filters_sidebar_sectionl.sidebar_section.panel" do
      div ".box.box-primary" do
        div ".box-header.with-border" do
          h3 ".box-title Filters"
        end
        form "accept-charset": "UTF-8", action: get_route_path(conn, :index), class: "filter_form", id: "q_search", method: "get" do
          div ".box-body.sidebar_section" do
            if scope do
              input type: :hidden, name: :scope, value: scope
            end
            for field <- fields(defn), do: build_field(field, q, defn)
          end
          div ".box-footer" do
            input name: "commit", type: "submit", value: "Filter", class: "btn btn-primary"
            a ".clear_filters_btn Clear Filters", href: "#", style: "padding-left: 10px"
            order_value = if order, do: order, else: "id_desc"
            input id: "order", name: "order", type: :hidden, value: order_value
          end
        end
      end
    end

  end

  def fields(%{index_filters: []} = defn) do
    for field <- defn.resource_model.__schema__(:fields) -- [:id] do
      {field, defn.resource_model.__schema__(:type, field)}
    end
  end

  def fields(%{index_filters: [filters]} = defn) do
    for field <- filters do
      {field, defn.resource_model.__schema__(:type, field)}
    end
  end

  def associations(defn) do
    Enum.reduce defn.resource_model.__schema__(:associations), [], fn(assoc, acc) -> 
      case defn.resource_model.__schema__(:association, assoc) do
        %Ecto.Association.BelongsTo{} = belongs_to -> [{assoc, belongs_to} | acc]
        _ -> acc
      end
    end
  end

  def build_field({name, :string}, q, _) do
    name_field = "#{name}_contains"
    value = if q, do: Map.get(q, name_field, ""), else: ""
    div ".form-group" do
      label ".label Search #{humanize name}", for: "q_#{name}"
      input id: "q_#{name}", name: "q[#{name_field}]", type: :text, value: value, class: "form-control"
    end
  end

  def build_field({name, type}, q, _) when type in [Ecto.DateTime, Ecto.Date, Ecto.Time] do
    gte_value = get_value("#{name}_gte", q)
    lte_value = get_value("#{name}_lte", q)
    div ".form-group" do
      label ".label #{humanize name}", for: "q_#{name}_gte"
      div ".row" do
        div ".col-xs-6", style: "padding-right: 5px;" do
          div ".input-group" do
            div ".input-group-addon" do
              i ".fa.fa-calendar"
            end
            input class: "datepicker form-control", id: "q_#{name}_gte", max: "10", name: "q[#{name}_gte]", size: "15", type: :text, value: gte_value
          end
        end

        div ".col-xs-6", style: "padding-left: 5px;" do
          div ".input-group" do
            div ".input-group-addon" do
              i ".fa.fa-calendar"
            end
            input class: "datepicker form-control", id: "q_#{name}_lte", max: "10", name: "q[#{name}_lte]", size: "15", type: :text, value: lte_value
          end
        end
      end
    end
  end

  def build_field({name, num}, q, defn) when num in [:integer, :id, :decimal] do
    unless check_and_build_association(name, q, defn) do
      selected_name = integer_selected_name(name, q)
      value = get_integer_value name, q
      div ".form-group" do
        label ".label #{humanize name}", for: "#{name}_numeric"
        div ".row" do
          div ".col-xs-6" do
            span ".input-group-addon" do
              select onchange: ~s|document.getElementById('#{name}_numeric').name = 'q[' + this.value + ']';| do
                for {suffix, text} <- @integer_options do
                  build_option(text, "#{name}_#{suffix}", selected_name)
                end
              end
            end
          end
          div ".col-xs-6", style: "padding-left: 0px" do
            input id: "#{name}_numeric", name: "q[#{selected_name}]", size: "10", type: "text", value: value, class: "form-control"
          end
        end
      end
    end
  end

  def build_field({name, %Ecto.Association.BelongsTo{related: assoc, owner_key: owner_key}}, q, _) do
    id = "q_#{owner_key}"
    if assoc.__schema__(:type, :name) do
      repo = Application.get_env :ex_admin, :repo
      resources = repo.all Ecto.Query.select(assoc, [c], {c.id, c.name})
      selected_key = case q["#{owner_key}_eq"] do
        nil -> nil
        val -> val
      end
      div ".form-group" do
        title = humanize(name) |> String.replace(" Id", "")
        label ".label #{title}", for: "q_#{owner_key}"
        select "##{id}.form-control", [name: "q[#{owner_key}_eq]"] do
          option "Any", value: ""
          for {id, name} <- resources do
            selected = if "#{id}" == selected_key, do: [selected: :selected], else: []
            option name, [{:value, "#{id}"} | selected]
          end
        end
      end
    end
  end

  def build_field({name, :boolean}, q, _) do
    name_field = "#{name}_eq"
    opts = [id: "q_#{name}", name: "q[#{name_field}]", type: :checkbox, value: "true", class: "form-control"]
    new_opts = if q do 
      if Map.get(q, name_field, nil), do: [{:checked, :checked} | opts], else: opts
    else 
      opts
    end
    div ".form-group" do
      label ".label #{humanize name}", for: "q_#{name}"
      input new_opts
    end
  end

  def build_field({name, Ecto.UUID}, q, defn) do
    repo = Application.get_env :ex_admin, :repo
    ids = repo.all(defn.resource_model)
    |> Enum.map(&(Map.get(&1, name)))

    selected_key = case q["#{name}_eq"] do
      nil -> nil
      val -> val
    end

    div ".form-group" do
      title = humanize(name)
      label ".label #{title}", for: "q_#{name}"
      select "##{name}", [name: "q[#{name}_eq]", class: "form-control"] do
        option "Any", value: ""
        for id <- ids do
          selected = if "#{id}" == selected_key, do: [selected: :selected], else: []
          option id, [{:value, "#{id}"} | selected]
        end
      end
    end
  end

  def build_field({name, type}, _q, _) do
    Logger.warn "ExAdmin.Filter: unknown type: #{inspect type} for field: #{inspect name}"
    nil
  end

  defp check_and_build_association(name, q, defn) do
    name_str = Atom.to_string name
    if String.match? name_str, ~r/_id$/ do
      Enum.map(defn.resource_model.__schema__(:associations), &(defn.resource_model.__schema__(:association, &1)))
      |> Enum.find(fn(assoc) -> 
        case assoc do
          %Ecto.Association.BelongsTo{owner_key: ^name} -> 
            build_field {name, assoc}, q, defn
            true
          _ -> 
            false
        end
      end)
    else
      false
    end
  end

  defp integer_selected_name(name, nil), do: "#{name}_eq"
  defp integer_selected_name(name, q) do
    Enum.reduce(@integer_options, "#{name}_eq", fn({k,_}, acc) -> 
      if q["#{name}_#{k}"], do: "#{name}_#{k}", else: acc
    end)
  end

  defp get_value(_, nil), do: ""
  defp get_value(name, q), do: Map.get(q, name, "")

  defp get_integer_value(_, nil), do: ""
  defp get_integer_value(name, q) do
    Map.to_list(q)
    |> Enum.find(fn({k,_v}) -> String.starts_with?(k, "#{name}") end)
    |> case do
      {_k, v} -> v
      _ -> ""
    end
  end

  defp build_option(text, name, selected_name) do
    selected = if name == selected_name, do: [selected: "selected"], else: []
    option text, [value: name] ++ selected
  end

end
