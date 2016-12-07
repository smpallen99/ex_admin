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

  by default, the user's name for each entry in the drop down list is fetched
  with the `:name` field of the user schema. See the following for examples on
  how to change this default:

      # change the field in `config/dev.exs`
      config :ex_admin,
        current_user_name: :full_name,
        current_user_name: &MyProject.User.user_name/1,
        current_user_name: {MyProject.User, :user_name}

      # as an option to the plug call in `web/router.ex`
      plug ExAdmin.Plug.SwitchUser, current_user_name: :full_name
      plug ExAdmin.Plug.SwitchUser, &MyProject.User.user_name/1
      plug ExAdmin.Plug.SwitchUser, {MyProject.User, :user_name}

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
      name = get_user_name(user, opts[:current_user_name])
      id   = Map.get(user, opts[:current_user_id])
      path = Utils.admin_path(:switch_user, [user.id])
      {name, id, path}
    end)
    assign(conn, :switch_users, [Map.get(current_user, opts[:current_user_id]) | users])
  end

  defp get_user_name(user, name_opt) when is_function(name_opt), do: name_opt.(user)
  defp get_user_name(user, name_opt) when is_atom(name_opt), do: Map.get(user, name_opt)
  defp get_user_name(user, {mod, fun}), do: apply(mod, fun, [user])

end
