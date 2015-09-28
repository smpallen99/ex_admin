defmodule ExAdmin.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Survey.Web, :controller
      use Survey.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Model
      
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      import Ecto.Model
      import Ecto.Query, only: [from: 1, from: 2]

      import ExAdmin.Router.Helpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import ExAdmin.Router.Helpers
      #import ExAuth
      import ExAdmin.ViewHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      # alias Application.get_env(:ex_admin, :repo)
      # import Application.get_env(:ex_admin, :repo)
      import Ecto.Model
      import Ecto.Query, only: [from: 1, from: 2]

    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
