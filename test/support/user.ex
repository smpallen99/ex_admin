defmodule ExAdminTest.User do
  use Ecto.Model
  import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string
    has_many :blogs, ExAdminTest.Blog
    has_many :comments, ExAdminTest.Comment
    has_many :posts, ExAdminTest.Post

    timestamps
  end

  @required_fields ~w(name email password)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
