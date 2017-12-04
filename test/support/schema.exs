defmodule TestExAdmin.User do
  import Ecto.Changeset
  use Ecto.Schema
  import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string
    field :active, :boolean, default: true
    has_many :products, TestExAdmin.Product, on_replace: :delete
    has_many :noids, TestExAdmin.Noid
    many_to_many :roles, TestExAdmin.Role, join_through: TestExAdmin.UserRole, on_replace: :delete
  end

  @fields ~w(name active email)a
  @required_fields ~w(email)a

  def changeset(model, params \\ %{}) do
    model

    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:noids, required: false)
    |> cast_assoc(:products, required: false)
    |> add_roles(params)
  end

  def add_roles(changeset, params) do
    if Enum.count(Map.get(params, :roles, [])) > 0 do
      ids = params[:roles]
      roles = TestExAdmin.Repo.all(from r in TestExAdmin.Role, where: r.id in ^ids)
      put_assoc(changeset, :roles, roles)
    else
      changeset
    end
  end
end

defmodule TestExAdmin.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias TestExAdmin.Repo

  schema "roles" do
    field :name, :string
    has_many :uses_roles, TestExAdmin.UserRole
    many_to_many :users, TestExAdmin.User, join_through: TestExAdmin.UserRole
  end

  @fields ~w(name)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  def all do
    Repo.all __MODULE__
  end
end

defmodule TestExAdmin.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_roles" do
    belongs_to :user, TestExAdmin.User
    belongs_to :role, TestExAdmin.Role

    timestamps()
  end

  @fields ~w(user_id role_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end

defmodule TestExAdmin.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :_destroy, :boolean, virtual: true
    field :title, :string
    field :price, :decimal
    belongs_to :user, TestExAdmin.User
  end

  @fields ~w(title price user_id)a
  @required_fields ~w(title price)a

  def changeset(model, params \\ %{}) do
    model

    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> mark_for_deletion()
  end

  defp mark_for_deletion(changeset) do
    # If delete was set and it is true, let's change the action
    if get_change(changeset, :_destroy) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end

defmodule TestExAdmin.Noid do
  import Ecto.Changeset
  use Ecto.Schema
  @primary_key {:name, :string, []}
  # @derive {Phoenix.Param, key: :name}
  schema "noids" do
    field :description, :string
    field :company, :string
    belongs_to :user, TestExAdmin.User, foreign_key: :user_id, references: :id
  end

  @fields ~w(name description company user_id)a
  @required_fields ~w(name description)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end

defmodule TestExAdmin.Noprimary do
  import Ecto.Changeset
  use Ecto.Schema
  @primary_key false
  schema "noprimarys" do
    field :index, :integer
    field :name, :string
    field :description, :string
    timestamps()
  end

  @fields ~w(index description name)a
  @required_fields ~w(name)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end

defmodule TestExAdmin.Simple do
  import Ecto.Changeset
  use Ecto.Schema

  schema "simples" do
    field :name, :string
    field :description, :string
    field :exists?, :boolean, virtual: true

    timestamps()
  end

  @fields ~w(name description)a
  @required_fields ~w(name)a

  def changeset(model, params \\ %{}) do
    Agent.update(__MODULE__, fn (_v) -> "changeset" end)
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def start_link do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def changeset_create(model, params \\ %{}) do
    Agent.update(__MODULE__, fn (_v) -> "changeset_create" end)
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def changeset_update(model, params \\ %{}) do
    Agent.update(__MODULE__, fn (_v) -> "changeset_update" end)
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def last_changeset do
    Agent.get(__MODULE__, fn changeset -> changeset end)
  end

  def stop do
    Agent.stop(__MODULE__)
  end
end

defmodule TestExAdmin.Restricted do
  import Ecto.Changeset
  use Ecto.Schema

  schema "restricteds" do
    field :name, :string
    field :description, :string

  end

  @fields ~w(name description)a
  @required_fields ~w(name)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end

defmodule TestExAdmin.PhoneNumber do
  import Ecto.Changeset
  use Ecto.Schema
  import Ecto.Query
  alias __MODULE__
  alias TestExAdmin.Repo

  schema "phone_numbers" do
    field :number, :string
    field :label, :string
    has_many :contacts_phone_numbers, TestExAdmin.ContactPhoneNumber
    has_many :contacts, through: [:contacts_phone_numbers, :contact]
    timestamps()
  end

  @fields ~w(number label)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  def labels, do: ["Primary Phone", "Secondary Phone", "Home Phone",
                   "Work Phone", "Mobile Phone", "Other Phone"]

  def tuple_labels, do: [{"primary phone", "Primary Phone"}, {"secondary phone", "Secondary Phone"}, {"home phone", "Home Phone"},
                         {"work phone", "Work Phone"}, {"mobile phone", "Mobile Phone"}, {"other phone", "Other Phone"}]

  def all_labels do
    (from p in PhoneNumber, group_by: p.label, select: p.label)
    |> Repo.all
  end
end

defmodule TestExAdmin.Contact do
  import Ecto.Changeset
  use Ecto.Schema

  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    has_many :contacts_phone_numbers, TestExAdmin.ContactPhoneNumber
    has_many :phone_numbers, through: [:contacts_phone_numbers, :phone_number]
    timestamps()
  end

  @fields ~w(first_name last_name)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end

defmodule TestExAdmin.ContactPhoneNumber do
  import Ecto.Changeset
  use Ecto.Schema

  schema "contacts_phone_numbers" do
    belongs_to :contact, TestExAdmin.Contact
    belongs_to :phone_number, TestExAdmin.PhoneNumber
  end

  @fields ~w(contact_id phone_number_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end

defmodule TestExAdmin.UUIDSchema do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:key, :binary_id, autogenerate: true}

  schema "uuid_schemas" do
    field :name, :string
    timestamps()
  end

  @fields ~w(name)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

end

defmodule TestExAdmin.ModelDisplayName do
  use Ecto.Schema

  schema "model_display_name" do
    field :first, :string
    field :name, :string
    field :other, :string
  end

  def display_name(resource) do
    resource.other
  end

  def model_name do
    "custom_name"
  end
end

defmodule TestExAdmin.DefnDisplayName do
  use Ecto.Schema

  schema "defn_display_name" do
    field :first, :string
    field :second, :string
    field :name, :string
  end
end

defmodule TestExAdmin.Maps do
  use Ecto.Schema

  schema "maps" do
    field :name, :string
    field :addresses, {:array, :map}
    field :stats, :map
  end
end
