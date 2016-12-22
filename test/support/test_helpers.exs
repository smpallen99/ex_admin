defmodule TestExAdmin.TestHelpers do
  alias TestExAdmin.Repo

  def insert_noid(attrs \\ %{}) do

    changes = Map.merge(%{
      name: "test name",
      description: "test description",
      company: "test company"
    }, to_map(attrs))

    TestExAdmin.Noid.changeset(%TestExAdmin.Noid{}, changes)
    |> Repo.insert!()
  end

  def insert_simple(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "test name",
      description: "test description",
    }, to_map(attrs))

    TestExAdmin.Simple.changeset(%TestExAdmin.Simple{}, changes)
    |> Repo.insert!()
  end

  def insert_restricted(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "test name",
      description: "test description",
    }, to_map(attrs))

    TestExAdmin.Restricted.changeset(%TestExAdmin.Restricted{}, changes)
    |> Repo.insert!()
  end

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "user one",
      email: "userone@example.com"
      }, to_map(attrs))
    TestExAdmin.User.changeset(%TestExAdmin.User{}, changes)
    |> Repo.insert!()
  end

  defp to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp to_map(attrs), do: attrs

end
