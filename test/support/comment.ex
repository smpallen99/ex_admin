defmodule ExAdminTest.Comment do
  use Ecto.Model
  import Ecto.Query

  schema "comments" do
    field :body, :string
    belongs_to :user, ExAdminTest.User
    belongs_to :post, ExAdminTest.Post

    timestamps
  end

  @required_fields ~w(body)
  @optional_fields ~w(user_id post_id)

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
