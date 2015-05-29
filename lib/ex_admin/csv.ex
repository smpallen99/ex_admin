defmodule ExAdmin.CSV do
  require Logger

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__), only: [csv: 1]
    end
  end

  defmacro csv(do: block) do
    quote do
      import ExAdmin.Register, except: [column: 3]
      import ExAdmin.Builder
      import ExAdmin.Register, only: [query: 1]
      import unquote(__MODULE__)

      require Logger

      module = Module.get_attribute(__MODULE__, :module)

      defimpl ExAdmin.View.Adapter, for: module do
        def build_csv(_, resources) do
          build :csv do
            unquote(block)
          end
          |> ExAdmin.CSV.build_csv(resources)
        end
      end
    end
  end

  defmacro column(field, fun) do
    quote do
      entry = %{field: unquote(field), fun: unquote(fun)}
      #Logger.warn "Column entry: #{inspect entry}"
      put :csv, entry
    end
  end

  def build_csv(schema, resources) do
    Enum.reduce(resources, build_header_row(schema), &(build_row &2, &1, schema))
    |> Enum.reverse
    |> CSVLixir.write
  end
  def build_csv(resources) do
    default_schema(resources)
    |> build_csv(resources)
  end

  def build_header_row(schema) do
    [(for field <- schema, do: field[:field])]
  end

  def build_row(acc, resource, schema) do
    [(for field <- schema, do: field[:fun].(resource)) | acc]
  end

  def default_schema([]), do: []
  def default_schema([resource | _]) do
    resource.__struct__.__schema__(:fields)
    |> Enum.map(&(build_default_column(&1)))
  end

  def build_default_column(name) do
    %{field: ExAdmin.Utils.humanize(name), fun: fn(c) -> to_string Map.get(c, name) end}
  end

  # def column(builder, name, fun) do

  # end


end
