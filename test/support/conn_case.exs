defmodule TestExAdmin.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias TestExAdmin.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]

      import TestExAdmin.Router.Helpers
      import TestExAdmin.TestHelpers
      import TestExAdmin.ErrorView
      import ExAdmin.Utils

      # The default endpoint for testing
      @endpoint TestExAdmin.Endpoint
      unless function_exported?(Phoenix.ConnTest, :build_conn, 0) do
        def build_conn, do: Phoenix.ConnTest.conn()
      end
    end
  end

  setup _tags do
    conn =
      if function_exported?(Phoenix.ConnTest, :build_conn, 0) do
        Phoenix.ConnTest.build_conn()
      else
        Phoenix.ConnTest.conn()
      end

    {:ok, conn: conn}
  end
end
