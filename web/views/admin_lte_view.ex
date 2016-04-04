defmodule ExAdmin.AdminLte.LayoutView do
  require Logger
  import ExAdmin.ViewHelpers
  import ExAdmin.Authentication

  file_path = __ENV__.file
  |> Path.dirname
  |> String.split("/views")
  |> hd
  |> Path.join("templates")
  |> Path.join("themes")

  use Phoenix.View, root: file_path
  # use Phoenix.View, root: "web/templates"

  # Import convenience functions from controllers
  import Phoenix.Controller, only: [view_module: 1]

  # Use all HTML functionality (forms, tags, etc)
  use Phoenix.HTML

  import ExAdmin.Router.Helpers
  #import ExAuth
  import ExAdmin.ViewHelpers
  import ExAdmin.LayoutView, only: [site_title: 0, check_for_sidebars: 3, admin_static_path: 2]
end
