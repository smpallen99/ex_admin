defmodule TestExAdmin.TestHelpers do
  alias TestExAdmin.Repo

  def insert_noid(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "test name",
      description: "test description",
      company: "test company"
    }, attrs)

    TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, changes)
    |> Repo.insert!()
  end

  def insert_user(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "user one",
      email: "userone@example.com"
      }, attrs)
    TestExAdmin.User.changeset(%TestExAdmin.User{}, changes)
    |> Repo.insert!()
  end
end
