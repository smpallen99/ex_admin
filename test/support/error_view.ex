defmodule TestExAdmin.ErrorView do
  use Phoenix.View, root: ""
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
  use Phoenix.HTML

  def render("404.html", _assigns) do
    "Not found"
  end

  def render("500.html", _assigns) do
    "Server internal error"
  end
 end