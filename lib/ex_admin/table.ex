defmodule ExAdmin.Table do
  require Logger
  require Integer
  use Xain
  import ExAdmin.Helpers
  import ExAdmin.Utils
  import Kernel, except: [to_string: 1]

  def attributes_table(_conn, resource, schema) do
    resource_name = model_name(resource)

    div(".panel") do
      h3(Map.get schema, :name, "#{String.capitalize resource_name} Details")
      div(".panel_contents") do
        id = "attributes_table_#{resource_name}_#{resource.id}"
        div(".attributes_table.#{resource_name}#{id}") do
          table(border: "0", cellspacing: "0", cellpadding: "0") do
            tbody do
              for field_name <- Map.get(schema, :rows, []) do
                build_field(resource, field_name, fn(contents, field_name) -> 
                  tr do
                    th(humanize field_name) 
                    handle_contents(contents, field_name)
                  end
                end)
              end
            end
          end
        end
      end
    end
  end

  def panel(schema) do
    div(".panel") do
      h3(Map.get schema, :name, "")
      div(".panel_contents") do
        case schema do
          %{table_for: %{resources: resources, columns: columns}} -> 
            table(border: "0", cellspacing: "0", cellpadding: "0") do
              table_head(columns)
              tbody do
                model_name = get_resource_name resources

                Enum.with_index(resources)
                |> Enum.map(fn({resource, inx}) -> 
                  odd_even = if Integer.is_even(inx), do: "even", else: "odd"
                  tr(".#{odd_even}##{model_name}_#{inx}") do
                    for field <- columns do
                      case field do
                        {f_name, fun} when is_function(fun) -> 
                          td ".#{f_name} #{fun.(resource)}"
                        {f_name, opts} -> 
                          build_field(resource, {f_name, Enum.into(opts, %{})}, fn(contents, f_name) -> 
                            td ".#{f_name} #{contents}"
                          end)
                      end
                    end
                  end
                end)
              end
            end
          end
      end
    end
  end

  def table_head(columns, opts \\ %{}) do
    selectable = Map.get opts, :selectable_column

    thead do
      tr do
        if selectable do
          th(".selectable") do
            div(".resource_selection_toggle_cell") do
              input("#collection_selection_toggle_all.toggle_all", type: "checkbox", name: "collection_selection_toggle_all")
            end
          end
        end
        for field <- columns do
          build_th field, opts
        end
      end
    end
  end

  def build_th({field_name, opts}, table_opts) when is_atom(field_name), do: build_th(Atom.to_string(field_name), opts, table_opts)
  def build_th({field_name, opts}, table_opts) when is_binary(field_name), do: build_th(field_name, opts, table_opts)

  def build_th(field_name, _),
    do: th(".#{field_name} #{humanize field_name}")

  def build_th(field_name, opts, %{fields: fields} = table_opts) do
    if String.to_atom(field_name) in fields and opts == %{} do
      _build_th(field_name, opts, table_opts)
    else
      th(".#{field_name} #{humanize field_name}") 
    end
  end

  def build_th(field_name, _, _) when is_binary(field_name) do
    th(class: to_class(field_name)) do
      text field_name
    end
  end 
  def build_th(field_name, _, _), do: build_th(field_name, nil)

  def _build_th(field_name, _opts, %{path_prefix: path_prefix, order: {name, sort}, 
      fields: _fields}) when field_name == name do
    link_order = if sort == "desc", do: "asc", else: "desc"
    th(".sortable.sorted-#{sort}.#{field_name}") do
      a("#{humanize field_name}", href: path_prefix <> 
        field_name <> "_#{link_order}")
    end
  end

  def _build_th(field_name, _opts, %{path_prefix: path_prefix} = table_opts) do
    sort = Map.get(table_opts, :sort, "asc")
    th(".sortable.#{field_name}") do
      a("#{humanize field_name}", href: path_prefix <> 
        field_name <> "_#{sort}")
    end
  end
  def handle_contents(%Ecto.DateTime{} = dt, field_name) do
    td class: to_class(field_name) do
      text to_string(dt)
    end
  end
  def handle_contents(%{}, _field_name), do: []
  def handle_contents(contents, field_name) when is_binary(contents) do
    td(".#{to_class(field_name)}") do
      text contents
    end
  end
  def handle_contents({:safe, contents}, field_name) do
    handle_contents contents, field_name
  end
  def handle_contents(contents, field_name) do
    td(".#{to_class(field_name)}", contents)
  end

end

