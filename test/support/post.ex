defmodule ExAdminTest.Post do
  use Ecto.Model
  import Ecto.Query

  schema "posts" do
    field :title, :string
    field :body, :string
    belongs_to :user, ExAdminTest.User
    belongs_to :blog, ExAdminTest.Blog
    has_many :comments, ExAdminTest.Comment

    timestamps
  end

  @required_fields ~w(title body)
  @optional_fields ~w(user_id blog_id)

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
