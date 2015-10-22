defmodule ExAdminTest.Blog do
  use Ecto.Model
  import Ecto.Query

  schema "blogs" do
    field :name, :string
    belongs_to :user, ExAdminTest.User
    has_many :posts, ExAdminTest.Post

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w(user_id)

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
