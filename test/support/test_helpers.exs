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

  def insert_simple(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "test name",
      description: "test description",
    }, attrs)

    TestExAdmin.Simple.changeset(%TestExAdmin.Simple{}, changes)
    |> Repo.insert!()
  end

  def insert_restricted(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "test name",
      description: "test description",
    }, attrs)

    TestExAdmin.Restricted.changeset(%TestExAdmin.Restricted{}, changes)
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
