ExUnit.start()

Code.require_file "./support/schema.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__
Code.require_file "./support/migrations.exs", __DIR__
Code.require_file "./support/admin_resources.exs", __DIR__
Code.require_file "./support/router.exs", __DIR__
Code.require_file "./support/endpoint.exs", __DIR__
Code.require_file "./support/conn_case.exs", __DIR__
Code.require_file "./support/test_helpers.exs", __DIR__

defmodule ExAdmin.RepoSetup do
  use ExUnit.CaseTemplate
  setup_all do
    Ecto.Adapters.SQL.begin_test_transaction(TestExAdmin.Repo, [])
    on_exit fn -> Ecto.Adapters.SQL.rollback_test_transaction(TestExAdmin.Repo, []) end
    :ok
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestExAdmin.Repo, [])
    :ok
  end
end

_ = Ecto.Storage.down(TestExAdmin.Repo)
_ = Ecto.Storage.up(TestExAdmin.Repo)

{:ok, _pid} = TestExAdmin.Repo.start_link
{:ok, _pid} = TestExAdmin.Endpoint.start_link
_ = Ecto.Migrator.up(TestExAdmin.Repo, 0, TestExAdmin.Migrations, log: false)
Process.flag(:trap_exit, true)
