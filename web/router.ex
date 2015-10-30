defmodule ExAdmin.Router do
  @moduledoc """
  Router macro for ExAdmin sites.

  Provides a helper macro for adding up ExAdmin routes to your application.

  ## Examples:

      defmodule MyProject.Router do
        use MyProject.Web, :router
        use ExAdmin.Router
        ...
        # setup the ExAdmin routes on /admin
        admin_routes 

        scope "/", MyProject do
        ...
      end

  ## Options for `admin_routes`

  * `admin_routes :administration` - Sets a custom route to `/administrator` 
  * `admin_routes pipeline: :browser` - Uses your :browser pipeline
    and the default `/admin` route.
  * `admin-routes prefix: :administration, pipeline: :browser` - Uses
    your existing `:browser` pipeline and the custom `/administrator` route.
  
  """
  use ExAdmin.Web, :router

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Add ExAdmin Routes or your project's router

  Adds the routes required for ExAdmin

  ## Options

  * `:prefix` - Change the `/admin` prefix.
  * `:pipeline` - Use an existing pipeline.
  """
  defmacro admin_routes(opts \\ :admin) do
    quote do
      opts = case unquote(opts) do
        list when is_list(list) -> 
          Enum.into list, %{prefix: :admin, no_pipeline: list[:pipeline]}
        name -> 
          %{prefix: name, no_pipeline: false, pipeline: :admin}
      end
      prefix = opts[:prefix]
      unless opts[:no_pipeline] do
        pipeline opts[:pipeline] do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_flash
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end
      end
      scope "/", ExAdmin do
        pipe_through opts[:pipeline]
        
        get "/#{prefix}", AdminController, :index
        get "/#{prefix}/:resource/", AdminController, :index
        get "/#{prefix}/:resource/new", AdminController, :new
        get "/#{prefix}/:resource/csv", AdminController, :csv
        get "/#{prefix}/:resource/:id", AdminController, :show
        get "/#{prefix}/:resource/:id/edit", AdminController, :edit
        post "/#{prefix}/:resource/", AdminController, :create
        patch "/#{prefix}/:resource/:id", AdminController, :update
        put "/#{prefix}/:resource/:id", AdminController, :update
        delete "/#{prefix}/:resource/:id", AdminController, :destroy
        post "/#{prefix}/:resource/batch_action", AdminController, :batch_action
      end
    end
  end
end
