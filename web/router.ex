defmodule ExAdmin.Router do
  @moduledoc false
  use ExAdmin.Web, :router

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  # pipeline :browser do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   # plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  # end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  # scope "/", ExAdmin do
  #   pipe_through :browser
    
  #   #pipe_through :admin
  #   get "/:resource/", AdminController, :index
  #   get "/:resource/new", AdminController, :new
  #   get "/:resource/csv", AdminController, :csv
  #   get "/:resource/:id", AdminController, :show
  #   get "/:resource/:id/edit", AdminController, :edit
  #   post "/:resource/", AdminController, :create
  #   patch "/:resource/:id", AdminController, :update
  #   put "/:resource/:id", AdminController, :update
  #   delete "/:resource/:id", AdminController, :destroy
  #   post "/:resource/batch_action", AdminController, :batch_action

  #   get "/admin/:resource/", AdminController, :index
  #   get "/admin/:resource/new", AdminController, :new
  #   get "/admin/:resource/csv", AdminController, :csv
  #   get "/admin/:resource/:id", AdminController, :show
  #   get "/admin/:resource/:id/edit", AdminController, :edit
  #   post "/admin/:resource/", AdminController, :create
  #   patch "/admin/:resource/:id", AdminController, :update
  #   put "/admin/:resource/:id", AdminController, :update
  #   delete "/admin/:resource/:id", AdminController, :destroy
  #   post "/admin/:resource/batch_action", AdminController, :batch_action
  # end

  defmacro admin_routes(name \\ :admin) do
    quote do
      prefix = unquote(name)
      pipeline :admin do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        # plug :protect_from_forgery
        plug :put_secure_browser_headers
      end
      scope "/", ExAdmin do
        pipe_through :admin
        
        #pipe_through :admin
        # get "/:resource/", AdminController, :index
        # get "/:resource/new", AdminController, :new
        # get "/:resource/csv", AdminController, :csv
        # get "/:resource/:id", AdminController, :show
        # get "/:resource/:id/edit", AdminController, :edit
        # post "/:resource/", AdminController, :create
        # patch "/:resource/:id", AdminController, :update
        # put "/:resource/:id", AdminController, :update
        # delete "/:resource/:id", AdminController, :destroy
        # post "/:resource/batch_action", AdminController, :batch_action

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
