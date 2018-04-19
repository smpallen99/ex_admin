defmodule ExAdmin.CSV do
  @moduledoc """
  ExAdmin provides a CSV export link on the index page of each resource.
  The CSV file format can be customized with the `csv` macro.

  For example, give the following ecto model for Example.Contact:

      defmodule Example.Contact do
        use Ecto.Model

        schema "contacts" do
          field :first_name, :string, default: ""
          field :last_name, :string, default: ""
          field :email, :string, default: ""
          belongs_to :category, Example.Category
          has_many :contacts_phone_numbers, Example.ContactPhoneNumber
          has_many :phone_numbers, through: [:contacts_phone_numbers, :phone_number]
          has_many :contacts_groups, Example.ContactGroup
          has_many :groups, through: [:contacts_groups, :group]
        end
        ...
      end

  The following resource file will export the contact list as shown below:

      defmodule Example.ExAdmin.Contact do
        use ExAdmin.Register
        alias Example.PhoneNumber

        register_resource Example.Contact do
          csv [
            {"Surname", &(&1.last_name)},
            {:category, &(&1.category.name)},
            {"Groups", &(Enum.map(&1.groups, fn g -> g.name end) |> Enum.join("; "))},
          ] ++
            (for label <- PhoneNumber.all_labels do
              fun = fn c ->
                c.phone_numbers
                |> PhoneNumber.find_by_label(label)
                |> Map.get(:number, "")
              end
              {label, fun}
            end)
        end
      end

      # output.csv

      Surname,Given,Category,Groups,Home Phone,Business Phone,Mobile Phone
      Pallen,Steve,R&D,Groop 1;Groop2,555-555-5555,555,555,1234

  The macros available in the csv do block include

  * `column` - Define a column in the exported CSV file

  ## Examples

      # List format
      csv [:name, :description]

      # List format with functions
      csv [:id, {:name, fn item -> "Mr. " <> item.name end}, :description]

      # No header
      csv header: false do
        column :id
        column :name
      end

      # Don't humanize the header name
      csv [:name, :created_at], humanize: false

  """
  require Logger

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__), only: [csv: 1]
    end
  end

  @doc """
  Customize the exported CSV file.

  """
  defmacro csv(opts \\ [], block \\ [])

  defmacro csv(block_or_opts, block) do
    {block, opts} = if block == [], do: {block_or_opts, block}, else: {block, block_or_opts}

    quote location: :keep do
      import ExAdmin.Register, except: [column: 1, column: 2]
      import unquote(__MODULE__)

      def build_csv(resources) do
        var!(columns, ExAdmin.CSV) = []
        unquote(block)

        case var!(columns, ExAdmin.CSV) do
          [] ->
            unquote(block)
            |> ExAdmin.CSV.build_csv(resources, unquote(opts))

          schema ->
            schema
            |> Enum.reverse()
            |> ExAdmin.CSV.build_csv(resources, unquote(opts))
        end
      end
    end
  end

  @doc """
  Configure a column in the exported CSV file.

  ## Examples

      csv do
        column :id
        column :name, fn user -> "#\{user.first_name} #\{user.last_name}" end
        column :age
      end
  """
  defmacro column(field, fun \\ nil) do
    quote do
      entry = %{field: unquote(field), fun: unquote(fun)}
      var!(columns, ExAdmin.CSV) = [entry | var!(columns, ExAdmin.CSV)]
    end
  end

  @doc false
  def default_schema([]), do: []
  @doc false
  def default_schema([resource | _]) do
    resource.__struct__.__schema__(:fields)
    |> Enum.map(&build_default_column(&1))
  end

  @doc false
  def build_default_column(name) do
    %{field: name, fun: nil}
  end

  @doc false
  def build_csv(schema, resources, opts) do
    schema = normalize_schema(schema)

    Enum.reduce(resources, build_header_row(schema, opts), &build_row(&2, &1, schema))
    |> Enum.reverse()
    |> CSVLixir.write()
  end

  def build_csv(resources) do
    default_schema(resources)
    |> build_csv(resources, [])
  end

  defp normalize_schema(schema) do
    Enum.map(schema, fn
      {name, fun} -> %{field: name, fun: fun}
      name when is_atom(name) -> %{field: name, fun: nil}
      map -> map
    end)
  end

  @doc false
  def build_header_row(schema, opts) do
    if Keyword.get(opts, :header, true) do
      humanize? = Keyword.get(opts, :humanize, true)
      [for(field <- schema, do: column_name(field[:field], humanize?))]
    else
      []
    end
  end

  defp column_name(field, true), do: ExAdmin.Utils.humanize(field)
  defp column_name(field, _), do: Atom.to_string(field)

  @doc false
  def build_row(acc, resource, schema) do
    row =
      Enum.reduce(schema, [], fn
        %{field: name, fun: nil}, acc ->
          [Map.get(resource, name) |> ExAdmin.Render.to_string() | acc]

        %{field: _name, fun: fun}, acc ->
          [fun.(resource) |> ExAdmin.Render.to_string() | acc]
      end)
      |> Enum.reverse()

    [row | acc]
  end

  @doc false
  def write_csv(csv) do
    csv
    |> CSVLixir.write()
  end
end
