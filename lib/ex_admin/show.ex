defmodule ExAdmin.Show do
  import ExAdmin.DslUtils

  import Kernel, except: [div: 2]
  use Xain

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro show(resource, [do: block]) do
    contents = quote do
      unquote(block)
    end

    quote bind_quoted: [resource: escape(resource), contents: escape(contents)] do
      def show_view(var!(conn), unquote(resource) = var!(resource)) do 
        #var!(query_options) = []
        markup do
          unquote(contents)
        end
      end
    end
  end

  def default_show_view(conn, resource) do
    markup do
      default_attributes_table conn, resource
    end
  end

  def default_attributes_table(conn, resource) do
    [_, res | _] = conn.path_info 
    case ExAdmin.get_registered_by_controller_route(res) do
      nil -> 
        throw :invalid_route
      %{__struct__: _} = defn -> 
        columns = defn.resource_model.__schema__(:fields)
        |> Enum.filter(&(not &1 in [:id, :inserted_at, :updated_at]))
        |> Enum.map(&({translate_field(&1), %{}}))
        |> Enum.filter(&(not is_nil(&1)))
        ExAdmin.Table.attributes_table conn, resource, %{rows: columns}
    end
  end

  defp translate_field(field) do
    case Regex.scan ~r/(.+)_id$/, Atom.to_string(field) do
      [[_, assoc]] -> String.to_atom(assoc)
      _ -> field
    end
  end

  # defmacro attributes_table(do: block) do
  #   attributes_table nil, block
  # end
  defmacro attributes_table(name \\ nil, do: block) do
    quote location: :keep do
      var!(rows, ExAdmin.Show) = []
      unquote(block)
      rows = var!(rows, ExAdmin.Show) |> Enum.reverse
      name = unquote(name)
      schema = case name do
        nil -> 
          %{rows: rows}
        name -> 
          %{name: name, rows: rows}
      end
      ExAdmin.Table.attributes_table var!(conn), var!(resource), schema
    end 
  end

  # defmacro attributes_table(name \\ nil) do
  defmacro attributes_table do
    quote location: :keep do
      ExAdmin.Show.default_attributes_table(var!(conn), var!(resource))
    end
  end

  defmacro panel(name \\ "", do: block) do
    quote do
      var!(table_for, ExAdmin.Show) = []
      var!(contents, ExAdmin.Show) = [] 
      unquote(block)
      ExAdmin.Table.panel(var!(conn), %{name: unquote(name), 
        table_for: var!(table_for, ExAdmin.Show), 
        contents: var!(contents, ExAdmin.Show)})
    end
  end

  defmacro table_for(resources, do: block) do
    quote do
      var!(columns, ExAdmin.Show) = []
      unquote(block)
      columns = var!(columns, ExAdmin.Show) |> Enum.reverse
      var!(table_for, ExAdmin.Show) = %{resources: unquote(resources), columns: columns}
    end
  end

  defmacro markup_contents(do: block) do
    quote do
      content = markup :nested do
        unquote(block)
      end
      var!(contents, ExAdmin.Show) = %{contents: content}
    end
  end

end
