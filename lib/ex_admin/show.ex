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

  defmacro panel(name \\ "", do: block) do
    quote do
      var!(table_for, ExAdmin.Show) = []
      unquote(block)
      ExAdmin.Table.panel(var!(conn), %{name: unquote(name), table_for: var!(table_for, ExAdmin.Show)})
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

end
