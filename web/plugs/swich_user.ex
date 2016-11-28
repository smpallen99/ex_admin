defmodule ExAdmin.Plug.SwitchUser do
  @moduledoc """
  Allow users to switch to a different login.

  Adds a drop down menu item on the page header with a list of all users.
  Selecting a user, automatically logs out the current user and logs in
  the selected user.

  The login is automatic without requiring a password to be entered.

  Use of this feature should be restricted to dev and test environments.

  ## Configuration

  add the following to your project's `config/dev.exs` file

      config :ex_admin,
        logout_user: {Coherence.ControllerHelpers, :logout_user},
        login_user: {Coherence.ControllerHelpers, :login_user}

  add the following to your `web/route.ex` file

      pipeline :protected do
        plug :accepts, ["html"]
        # ...
        if Mix.env == :dev do
          plug ExAdmin.Plug.SwitchUser
        end
      end

  """
  @behaviour Plug
  import Plug.Conn
  import ExAdmin.Authentication
  alias ExAdmin.Utils
  require Logger


  def init(opts) do
    unless Application.get_env(:ex_admin, :login_user) && Application.get_env(:ex_admin, :logout_user) do
      raise """
        :login_user and :logout_user must be configured to use ExAdmin.Plug.SwitchUser.
        Please configure these and recompile your project.
        """
    end
    %{
      current_user_id: opts[:current_user_id] || Application.get_env(:ex_admin, :current_user_id, :id),
      current_user_name: opts[:current_user_name] || Application.get_env(:ex_admin, :current_user_name, :name),
      repo: Application.get_env(:ex_admin, :repo),
    }
  end

  def call(conn, opts) do
    current_user(conn)
    |> do_call(conn, opts)
  end

  def do_call(nil, conn, _), do: conn
  def do_call(current_user, conn, opts) do
    users = opts[:repo].all(current_user.__struct__)
    |> Enum.map(fn user ->
      name = Map.get(user, opts[:current_user_name])
      id   = Map.get(user, opts[:current_user_id])
      path = Utils.admin_path(:switch_user, [user.id])
      {name, id, path}
    end)
    assign(conn, :switch_users, [Map.get(current_user, opts[:current_user_id]) | users])
  end

end
