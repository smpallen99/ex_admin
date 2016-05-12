defmodule TestExAdmin.TestHelpers do
  alias TestExAdmin.Repo

  def insert_noid(attrs \\ %{}) do
    %{
      name: "test name",
      description: "test description",
      company: "test company"
    }
    |> insert(attrs, TestExAdmin.Noid)
  end

  def insert_user(attrs \\ %{}) do
    %{
      name: "user one",
      email: "userone@example.com"
    }
    |> insert(attrs, TestExAdmin.User)
  end

  defp insert(defaults, attrs, module) do
    changes = Dict.merge(defaults, attrs)
    module.changeset(module.__struct__, changes)
    |> Repo.insert!()
  end
end
