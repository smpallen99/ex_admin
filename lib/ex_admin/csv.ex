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
          csv do
            column "Surname", fn c -> c.last_name end
            column "Given", fn c -> c.first_name end
            column "Category", fn c -> c.category.name end

            column "Groups", fn c -> 
              Enum.map(c.groups, &(&1.name))
              |> Enum.join("; ")
            end

            for label <- PhoneNumber.all_labels do
              column label, fn c -> 
                c.phone_numbers
                |> PhoneNumber.find_by_label(label)
                |> Map.get(:number, "")
              end
            end
          end
        end
      end

  # output.csv

  Surname,Given,Category,Groups,Home Phone,Business Phone,Mobile Phone
  Pallen,Steve,R&D,Groop 1;Groop2,555-555-5555,555,555,1234

  The macros available in the csv do block include"

  * `column` - Define a column in the exported CSV file
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

  @doc """
  Configure a column in the exported CSV file.
  """
  defmacro column(field, fun) do
    quote do
      entry = %{field: unquote(field), fun: unquote(fun)}
      #Logger.warn "Column entry: #{inspect entry}"
      put :csv, entry
    end
  end

  @doc false
  def build_csv(schema, resources) do
    Enum.reduce(resources, build_header_row(schema), &(build_row &2, &1, schema))
    |> Enum.reverse
    |> CSVLixir.write
  end
  @doc false
  def build_csv(resources) do
    default_schema(resources)
    |> build_csv(resources)
  end

  @doc false
  def build_header_row(schema) do
    [(for field <- schema, do: field[:field])]
  end

  @doc false
  def build_row(acc, resource, schema) do
    [(for field <- schema, do: field[:fun].(resource)) | acc]
  end

  @doc false
  def default_schema([]), do: []
  @doc false
  def default_schema([resource | _]) do
    resource.__struct__.__schema__(:fields)
    |> Enum.map(&(build_default_column(&1)))
  end

  @doc false
  def build_default_column(name) do
    %{field: ExAdmin.Utils.humanize(name), fun: fn(c) -> to_string Map.get(c, name) end}
  end


end
