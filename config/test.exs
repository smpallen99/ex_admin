use Mix.Config

config :ex_admin, TestExAdmin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex_admin_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
