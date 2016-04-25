defmodule TestExAdmin.User do
  use Ecto.Schema 

  schema "users" do
    field :name, :string
    field :email, :string
    has_many :products, TestExAdmin.Product
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
  use Ecto.Model
  @primary_key {:name, :string, []}
  schema "noids" do
    field :description, :string

    timestamps
  end
  
  @required_fields ~w(name description)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

defmodule TestExAdmin.Noprimary do
  use Ecto.Model
  @primary_key false
  schema "noprimarys" do
    field :index, :integer
    field :name, :string
    field :description, :string

    timestamps
  end
end
