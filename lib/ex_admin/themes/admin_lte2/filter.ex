Code.ensure_compiled(ExAdmin.Utils)

defmodule ExAdmin.Theme.AdminLte2.Filter do
  @moduledoc false
  require Logger
  require Ecto.Query
  import ExAdmin.Utils
  import ExAdmin.Gettext
  import ExAdmin.Filter
  use Xain

  def theme_filter_view(conn, defn, q, order, scope) do
    markup safe: true do
      div ".box.box-primary" do
        div ".box-header.with-border" do
          h3(".box-title " <> gettext("Filters"))
        end

        form "accept-charset": "UTF-8",
             action: admin_resource_path(conn, :index),
             class: "filter_form",
             id: "q_search",
             method: "get" do
          div ".box-body.sidebar_section" do
            if scope do
              input(type: :hidden, name: :scope, value: scope)
            end

            for field <- fields(defn), do: build_field(field, q, defn)
            for field <- associations(defn), do: build_field(field, q, defn)
          end

          div ".box-footer" do
            input(
              name: "commit",
              type: "submit",
              value: gettext("Filter"),
              class: "btn btn-primary"
            )

            a(
              ".clear_filters_btn " <> gettext("Clear Filters"),
              href: "#",
              style: "padding-left: 10px"
            )

            order_value = if order, do: order, else: "id_desc"
            input(id: "order", name: "order", type: :hidden, value: order_value)
          end
        end
      end
    end
  end

  def build_field({name, :string}, q, defn) do
    selected_name = string_selected_name(name, q)
    value = get_string_value(name, q)
    name_label = field_label(name, defn)
    # value = if q, do: Map.get(q, name_field, ""), else: ""
    div ".form-group" do
      label(
        ".label " <> gettext("Search %{name_label}", name_label: name_label),
        for: "q_#{name}"
      )

      div ".row" do
        div ".col-xs-6", style: "padding-right: 0" do
          span ".input-group-addon" do
            div ".filter-select" do
              select onchange:
                       ~s|document.getElementById("q_#{name}").name = "q[" + this.value + "]";| do
                for {suffix, text} <- string_options() do
                  build_option(text, "#{name}_#{suffix}", selected_name)
                end
              end

              i(".fa.fa-sort", style: "margin-left: -20px")
            end
          end
        end

        div ".col-xs-6", style: "padding-left: 0px" do
          input(
            id: "q_#{name}",
            name: "q[#{selected_name}]",
            type: "text",
            value: value,
            class: "form-control"
          )
        end
      end
    end
  end

  def build_field({name, type}, q, defn)
      when type in [
             Ecto.DateTime,
             Ecto.Date,
             Ecto.Time,
             Timex.Ecto.DateTime,
             Timex.Ecto.Date,
             Timex.Ecto.Time,
             Timex.Ecto.DateTimeWithTimezone,
             NaiveDateTime,
             :naive_datetime,
             DateTime,
             :utc_datetime
           ] do
    gte_value = get_value("#{name}_gte", q)
    lte_value = get_value("#{name}_lte", q)
    name_label = field_label(name, defn)

    div ".form-group" do
      label(".label #{name_label}", for: "q_#{name}_gte")

      div ".row" do
        div ".col-xs-6", style: "padding-right: 5px;" do
          div ".input-group" do
            div ".input-group-addon" do
              i(".fa.fa-calendar")
            end

            input(
              class: "datepicker form-control",
              id: "q_#{name}_gte",
              max: "10",
              name: "q[#{name}_gte]",
              size: "15",
              type: :text,
              value: gte_value
            )
          end
        end

        div ".col-xs-6", style: "padding-left: 5px;" do
          div ".input-group" do
            div ".input-group-addon" do
              i(".fa.fa-calendar")
            end

            input(
              class: "datepicker form-control",
              id: "q_#{name}_lte",
              max: "10",
              name: "q[#{name}_lte]",
              size: "15",
              type: :text,
              value: lte_value
            )
          end
        end
      end
    end
  end

  def build_field({name, num}, q, defn) when num in [:integer, :id, :decimal, :float] do
    unless check_and_build_association(name, q, defn) do
      selected_name = integer_selected_name(name, q)
      value = get_integer_value(name, q)
      name_label = field_label(name, defn)

      div ".form-group" do
        label(".label #{name_label}", for: "#{name}_numeric")

        div ".row" do
          div ".col-xs-6", style: "padding-right: 0" do
            span ".input-group-addon" do
              div ".filter-select" do
                select onchange:
                         ~s|document.getElementById("#{name}_numeric").name = "q[" + this.value + "]";| do
                  for {suffix, text} <- integer_options() do
                    build_option(text, "#{name}_#{suffix}", selected_name)
                  end
                end

                i(".fa.fa-sort", style: "margin-left: -20px")
              end
            end
          end

          div ".col-xs-6", style: "padding-left: 0px" do
            input(
              id: "#{name}_numeric",
              name: "q[#{selected_name}]",
              size: "10",
              type: "text",
              value: value,
              class: "form-control"
            )
          end
        end
      end
    end
  end

  def build_field(
        {name, %Ecto.Association.BelongsTo{related: assoc, owner_key: owner_key}},
        q,
        defn
      ) do
    id = "q_#{owner_key}"
    name_label = field_label(name, defn)
    resources = filter_resources(name, assoc, defn)

    selected_key =
      case q["#{owner_key}_eq"] do
        nil -> nil
        val -> val
      end

    div ".form-group" do
      title = name_label |> String.replace(" Id", "")
      label(".label #{title}", for: "q_#{owner_key}")

      select "##{id}.form-control", name: "q[#{owner_key}_eq]" do
        option("Any", value: "")

        for r <- resources do
          id = ExAdmin.Schema.get_id(r)
          name = ExAdmin.Helpers.display_name(r)
          selected = if "#{id}" == selected_key, do: [selected: :selected], else: []
          option(name, [{:value, "#{id}"} | selected])
        end
      end
    end
  end

  def build_field({name, :boolean}, q, defn) do
    name_label = field_label(name, defn)
    name_field = "#{name}_eq"
    opts = [id: "q_#{name}", name: "q[#{name_field}]", type: :checkbox, value: "true"]

    new_opts =
      if q do
        if Map.get(q, name_field, nil), do: [{:checked, :checked} | opts], else: opts
      else
        opts
      end

    div ".form-group" do
      label(".label #{name_label}", for: "q_#{name}")
      input(new_opts)
    end
  end

  def build_field({name, Ecto.UUID}, q, defn) do
    name_label = field_label(name, defn)
    repo = Application.get_env(:ex_admin, :repo)

    ids =
      repo.all(defn.resource_model)
      |> Enum.map(&Map.get(&1, name))

    selected_key =
      case q["#{name}_eq"] do
        nil -> nil
        val -> val
      end

    div ".form-group" do
      label(".label #{name_label}", for: "q_#{name}")

      select "##{name}", name: "q[#{name}_eq]", class: "form-control" do
        option("Any", value: "")

        for id <- ids do
          selected = if "#{id}" == selected_key, do: [selected: :selected], else: []
          option(id, [{:value, "#{id}"} | selected])
        end
      end
    end
  end

  def build_field({name, type}, _q, _) do
    Logger.debug("ExAdmin.Filter: unknown type: #{inspect(type)} for field: #{inspect(name)}")
    nil
  end
end
