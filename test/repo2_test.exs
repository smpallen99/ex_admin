defmodule ExAdmin.Repo2Test do
  use ExUnit.Case
  require Logger
  # import TestExAdmin.TestHelpers
  alias TestExAdmin.{Repo, Comment, Post}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
  end

  test "simple resource" do
    defn = %TestExAdmin.ExAdmin.Post{}
    {:ok, post} = ExAdmin.Changeset2.changeset(%Post{}, defn,
      %{"title" => "1", "text" => "11"})
    |> ExAdmin.Repo2.insert
    assert post.title == "1"
    assert post.text == "11"

    {:ok, post} = ExAdmin.Changeset2.changeset(post, defn,
      %{"title" => "111"})
    |> ExAdmin.Repo2.update
    assert post.title == "111"
    assert post.text == "11"
  end

  test "belongs_to assoc" do
    defn = %TestExAdmin.ExAdmin.Post{}
    params = %{
      "title" => "1", "text" => "11", "comments" => %{
        "100000000000009" => %{"text" => "2"},
        "100000000000010" => %{"text" => "4"},
       }
    }
    {:ok, post} = ExAdmin.Changeset2.changeset(%Post{}, defn, params)
    |> ExAdmin.Repo2.insert
    post = Repo.get!(Post, post.id) |> Repo.preload(:comments)
    assert post.title == "1"
    assert post.text == "11"
    [c1, c2] = post.comments |> Enum.sort(&(&1.id < &2.id))
    assert c1.text == "2"
    assert c2.text == "4"

    # update name and 1 post

    params = %{
      "title" => "1", "text" => "new 1", "comments" => %{
        "0" => %{"id" => c1.id, "text" => "22"},
        "1" => %{"id" => c2.id, "text" => "4"},
       }
    }
    {:ok, post} = ExAdmin.Changeset2.changeset(post, defn, params)
    |> ExAdmin.Repo2.update
    post = Repo.get!(Post, post.id) |> Repo.preload(:comments)
    assert post.title == "1"
    assert post.text == "new 1"
    [c1, c2] = post.comments |> Enum.sort(&(&1.id < &2.id))
    assert c1.text == "22"
    assert c2.text == "4"

    # update with new post

    params = %{
      "title" => "11", "text" => "new 1", "comments" => %{
        "0" => %{"id" => c1.id, "text" => "22"},
        "1" => %{"id" => c2.id, "text" => "4"},
        "2" => %{"text" => "6"},
       }
    }
    {:ok, post} = ExAdmin.Changeset2.changeset(post, defn, params)
    |> ExAdmin.Repo2.update
    post = Repo.get!(Post, post.id) |> Repo.preload(:comments)
    assert post.title == "11"
    assert post.text == "new 1"
    [c1, c2, c3] = post.comments |> Enum.sort(&(&1.id < &2.id))
    assert c1.text == "22"
    assert c2.text == "4"
    assert c3.text == "6"
  end

end
