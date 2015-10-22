use Mix.Config

config :ex_admin, ExAdminTest.Repo,
  adapter: Ecto.Adapters.MySQL,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ex_admin_test",
  username: System.get_env("EXADMIN_DB_USER") || System.get_env("USER")

config :logger, :console, 
  level: :error
