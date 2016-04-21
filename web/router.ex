defmodule ExAdmin.Router do
  @moduledoc """
  Router macro for ExAdmin sites.

  Provides a helper macro for adding up ExAdmin routes to your application.

  ## Examples:

      defmodule MyProject.Router do
        use MyProject.Web, :router
        use ExAdmin.Router
        ...
        scope "/", MyProject do
          ...
        end

        # setup the ExAdmin routes on /admin
        scope "/admin", ExAdmin do
          pipe_through :browser
          admin_routes
        end
      end
  
  """
  use ExAdmin.Web, :router

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Add ExAdmin Routes to your project's router

  Adds the routes required for ExAdmin
  """
  defmacro admin_routes(_opts \\ []) do
    quote do
      get "/", AdminController, :index
      get "/select_theme/:id", AdminController, :select_theme
      get "/:resource/", AdminController, :index
      get "/:resource/new", AdminController, :new
      get "/:resource/csv", AdminController, :csv
      get "/:resource/:id", AdminController, :show
      get "/:resource/:id/edit", AdminController, :edit
      post "/:resource/", AdminController, :create
      patch "/:resource/:id", AdminController, :update
      put "/:resource/:id", AdminController, :update
      delete "/:resource/:id", AdminController, :destroy
      post "/:resource/batch_action", AdminController, :batch_action
    end
  end
end
