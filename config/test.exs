use Mix.Config

config :ex_admin, ExAdminTest.Repo,
  adapter: Ecto.Adapters.MySQL,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ex_admin_test",
  username: System.get_env("EXADMIN_DB_USER") || System.get_env("USER")

config :ex_admin, 
  repo: ExAdminTest.Repo,
  module: ExAdminTest,
  modules: [
    ExAdminTest.ExAdmin.User,
    ExAdminTest.ExAdmin.Blog,
    ExAdminTest.ExAdmin.Post,
    ExAdminTest.ExAdmin.Comment,
  ]
config :logger, :console, 
  level: :error
