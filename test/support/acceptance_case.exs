defmodule TestExAdmin.AcceptanceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Hound.Helpers

      import Ecto.Schema
      import Ecto.Query, only: [from: 2]

      alias TestExAdmin.Repo
      import TestExAdmin.Router.Helpers
      import TestExAdmin.TestHelpers
      import TestExAdmin.ErrorView
      import ExAdmin.Utils
      import TestExAdmin.TestHelpers
      @endpoint TestExAdmin.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(TestExAdmin.Repo, self())
    Hound.start_session(metadata: metadata)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(TestExAdmin.Repo, {:shared, self()})
    end

    :ok
  end
end
