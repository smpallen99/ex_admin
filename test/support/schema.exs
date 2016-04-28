defmodule TestExAdmin.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    has_many :products, TestExAdmin.Product
    has_many :noids, TestExAdmin.Noid
  end

  @required_fields ~w(name email)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

defmodule TestExAdmin.Product do
  use Ecto.Schema

  schema "products" do
    field :title, :string
    field :price, :decimal
    belongs_to :user, TestExAdmin.User
  end
end

defmodule TestExAdmin.Noid do
  import Ecto.Changeset
  use Ecto.Schema
  @primary_key {:name, :string, []}
  @derive {Phoenix.Param, key: :name}
  schema "noids" do
    field :description, :string
    field :company, :string
    belongs_to :user, TestExAdmin.User, foreign_key: :user_id, references: :id

  end

  @required_fields ~w(name description)
  @optional_fields ~w(company user_id)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

defmodule TestExAdmin.Noprimary do
  use Ecto.Schema
  @primary_key false
  schema "noprimarys" do
    field :index, :integer
    field :name, :string
    field :description, :string

  end
end
