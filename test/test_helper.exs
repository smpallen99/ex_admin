Application.ensure_all_started(:hound)
ExUnit.configure(timeout: :infinity)
ExUnit.configure(exclude: [pending: true, integration: true])
ExUnit.start()

Code.require_file("./support/web.exs", __DIR__)
Code.require_file("./support/schema.exs", __DIR__)
Code.require_file("./support/router.exs", __DIR__)
Code.require_file("./support/repo.exs", __DIR__)
Code.require_file("./support/migrations.exs", __DIR__)
Code.require_file("./support/admin_resources.exs", __DIR__)
Code.require_file("./support/conn_case.exs", __DIR__)
Code.require_file("./support/acceptance_case.exs", __DIR__)
Code.require_file("./support/test_helpers.exs", __DIR__)
Code.require_file("./support/view.exs", __DIR__)
Code.require_file("./support/endpoint.exs", __DIR__)

defmodule ExAdmin.RepoSetup do
  use ExUnit.CaseTemplate
end

TestExAdmin.Repo.__adapter__().storage_down(TestExAdmin.Repo.config())
TestExAdmin.Repo.__adapter__().storage_up(TestExAdmin.Repo.config())

{:ok, _pid} = TestExAdmin.Repo.start_link()
{:ok, _pid} = TestExAdmin.Endpoint.start_link()
_ = Ecto.Migrator.up(TestExAdmin.Repo, 0, TestExAdmin.Migrations, log: false)
Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(TestExAdmin.Repo, :manual)
