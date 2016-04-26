ExUnit.start()

Code.require_file "./support/schema.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__
Code.require_file "./support/migrations.exs", __DIR__
Code.require_file "./support/admin_resources.exs", __DIR__

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

TestExAdmin.Repo.__adapter__.storage_down TestExAdmin.Repo.config
TestExAdmin.Repo.__adapter__.storage_up TestExAdmin.Repo.config

{:ok, _pid} = TestExAdmin.Repo.start_link
_ = Ecto.Migrator.up(TestExAdmin.Repo, 0, TestExAdmin.Migrations, log: false)
Process.flag(:trap_exit, true)
