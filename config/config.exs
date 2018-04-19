# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.
#
# config :ex_admin,
#   route_prefix: "admin",
#   repo: MyApp.Repo,
#   module: MyApp,
#   title: "MySiteTitle",      # header title
#   nest_resources: false,
#   nest_scopes: false,
#   scopes_index_page: false,
#   head_template: {ExAdminDemo.AdminView, "admin_layout.html"},
#   footer: "&copy; Project Name",
#   logo_mini: "Ex<b>A</b>",
#   logo_full: "Ex<b>Admin</b>",
#   theme: ExAdmin.Theme.ActiveAdmin,
#   skin_color: :blue, # ~w(blue black purple green red yellow blue-light
#                      # black-light purple-light green-light red-light yellow-light)
#   theme_selector: [
#     {"AdminLte",  ExAdmin.Theme.AdminLte2},
#     {"ActiveAdmin", ExAdmin.Theme.ActiveAdmin}
#   ],
#   login_user: nil,
#   logout_user: nil,
#   modules: [
#     Nested.ExAdmin.Dashboard,
#   ]
config :ex_admin,
  repo: MyProject.Repo,
  module: MyProject,
  modules: [],
  module: ExAdmin

config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine,
  eex: Phoenix.Template.EExEngine

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
