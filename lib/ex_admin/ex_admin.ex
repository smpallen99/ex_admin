defmodule ExAdmin do
  @moduledoc """
  ExAdmin is a an auto administration tool for the PhoenixFramework,
  providing a quick way to create a CRUD interface for administering
  Ecto models with little code and the ability to customize the
  interface if desired.

  After creating one or more Ecto models, the administration tool can
  be used by creating a resource model for each model. The basic
  resource file for model ... looks like this:

      # web/admin/my_model.ex

      defmodule MyProject.ExAdmin.MyModel do
        use ExAdmin.Register

        register_resource MyProject.MyModel do
        end
      end

  This file can be created manually, or by using the mix task:

      mix admin.gen.resource MyModel

  ExAdmin adds a menu item for the model in the admin interface, along
  with the ability to index, add, edit, show and delete instances of
  the model.

  Many of the pages in the admin interface can be customized for each
  model using a DSL. The following can be customized:

  * `index` - Customize the index page
  * `show` - Customize the show page
  * `form` - Customize the new and edit pages
  * `menu` - Customize the menu item
  * `controller` - Customer the controller

  ## Custom Ecto Types

  ### Map Type

  By default, ExAdmin used Poison.encode! to encode `Map` type. To change the
  decoding, add override the protocol. For Example:

      defimpl ExAdmin.Render, for: Map do
        def to_string(map) do
          {:ok, encoded} = Poison.encode map
          encoded
        end
      end

  As well as handling the encoding to display the data, you will need to handle
  the params decoding for the `:create` and `:modify` actions. You have a couple
  options for handling this.

  * In your changeset, you can update the params field with the decoded value
  * Add a controller `before_filter` in your admin resource file.

  For example:

      register_resource AdminIdIssue.UserSession do
        controller do
          before_filter :decode, only: [:update, :create]

          def decode(conn, params) do
            if get_in params, [:usersession, :data] do
              params = update_in params, [:usersession, :data], &(Poison.decode!(&1))
            end
            {conn, params}
          end
        end
      end

  ## Other Types

  To support other Ecto Types, implement the ExAdmin.Render protocol for the
  desired type. Here is an example from the ExAdmin code for the `Ecto.Date` type:

      defimpl ExAdmin.Render, for: Ecto.Date do
        def to_string(dt) do
          Ecto.Date.to_string dt
        end
      end

  ## Adding Custom CSS or JS to the Layout Head

  A configuration item is available to add your own CSS or JS files
  to the `<head>` section of ExAdmin's layout file.

  Add the following to your project's `config/config.exs` file:

    config :ex_admin,
      head_template: {ExAdminDemo.AdminView, "admin_layout.html"}

  Where:
  * `ExAdminDemo.AdminView` is a view in your project
  * `admin_layout.html` is a template in `web/templates/admin` directory

  For example:

      # file web/templates/admin/admin_layout.html.eex
      <link rel="stylesheet" href="<%= static_path(@conn, "/css/admin_custom.css") %>">

      # file priv/static/css/admin_custom.css
      .foo {
        color: green !important;
        font-weight: 600;
      }

  """
  require Logger
  use Xain
  alias ExAdmin.Utils
  import ExAdmin.Utils, only: [base_name: 1, titleize: 1, humanize: 1]
  require ExAdmin.Register

  @filename "/tmp/ex_admin_registered"
  Code.ensure_compiled ExAdmin.Register

  Module.register_attribute __MODULE__, :registered, accumulate: true, persist: true

  @default_theme ExAdmin.Theme.AdminLte2

  defmacro __using__(_) do
    quote do
      use ExAdmin.Index
      import unquote(__MODULE__)
    end
  end

  # check for old xain.after_callback format and issue a compile time
  # exception if not configured correctly.

  case Application.get_env :xain, :after_callback do
    nil -> nil
    {_, _} -> nil
    _ ->
      raise ExAdmin.CompileError, message: "Invalid xain_callback in config. Use {Phoenix.HTML, :raw}"
  end

  @doc false
  def registered, do: Application.get_env(:ex_admin, :modules, []) |> Enum.reverse

  @doc false
  def put_data(key, value) do
    Agent.update __MODULE__, &(Map.put(&1, key, value))
  end

  @doc false
  def get_data(key) do
    Agent.get __MODULE__, &(Map.get(&1, key))
  end

  @doc false
  def get_all_registered do
    for reg <- registered do
      case get_registered_resource(reg) do
        %{resource_model: rm} = item ->
          {rm, item}
        %{type: :page} = item ->
          {nil, item}
      end
    end
  end

  @doc false
  def get_registered_resource(name) do
    apply(name, :__struct__, [])
  end

  @doc false
  def get_registered do
    for reg <- registered do
      get_registered_resource(reg)
    end
  end
  @doc false
  def get_registered(resource_model) do
    get_all_registered
    |> Keyword.get(resource_model)
  end

  @doc false
  def get_registered_by_controller_route!(name, conn \\ %Plug.Conn{}) do
    res = get_registered_by_controller_route(name)
    if res == %{} do
      raise Phoenix.Router.NoRouteError, conn: conn, router: __MODULE__
    else
      res
    end
  end

  @doc false
  def get_registered_by_controller_route(%Plug.Conn{params: params}) do
    get_registered_by_controller_route params["resource"]
  end
  @doc false
  def get_registered_by_controller_route(path_info) when is_list(path_info) do
    case path_info do
      ["admin", route | _] -> route
      _ -> ""
    end
    |> get_registered_by_controller_route
  end

  @doc false
  def get_registered_by_controller_route(route) do
    Enum.find get_registered, %{}, &(Map.get(&1, :controller_route) == route)
  end

  @doc false
  def get_controller_path(%{} = resource) do
    get_controller_path Map.get(resource, :__struct__)
  end
  @doc false
  def get_controller_path(resource_model) when is_atom(resource_model) do
    get_all_registered
    |> Keyword.get(resource_model, %{})
    |> Map.get(:controller_route)
  end

  @doc false
  def get_title_actions(%Plug.Conn{private: _private, path_info: path_info} = conn) do
    defn = get_registered_by_controller_route(path_info)
    fun = defn |> Map.get(:title_actions)
    fun.(conn, defn)
  end

  @doc false
  def get_title_actions(name) do
    case get_registered(name) do
      nil ->
        &__MODULE__.default_page_title_actions/2
      %{title_actions: actions} ->
        actions
    end
  end

  @doc false
  def get_name_from_controller(controller) when is_atom(controller) do
    get_all_registered
    |> Enum.find_value(fn({name, %{controller: c_name}}) ->
      if c_name == controller, do: name
    end)
  end

  @doc false
  def default_resource_title_actions(%Plug.Conn{params: params} = conn, %{resource_model: _resource_model} = defn) do
    # Logger.warn "action name: #{inspect Utils.action_name(conn)}"
    singular = ExAdmin.Utils.displayable_name_singular(conn) |> titleize
    actions = defn.actions
    case Utils.action_name(conn) do
      :show ->
        id = Map.get(params, "id")
        for action <- [:edit, :new, :delete],
          do: {action, action_button(conn, defn, singular, :show, action, actions, id)}
        # id = Map.get(params, "id")
        # div(".action_items") do
        #   for action <- [:edit, :new, :delete],
        #     do: action_button(conn, defn, singular, :show, action, actions, id)
        # end

      action when action in [:index, :edit] ->
        [{action, action_button(conn, defn, singular, action, :new, actions)}]

      _ ->
        []
        # div(".action_items")
    end

  end

  @doc false
  def default_page_title_actions(_conn, _) do
    []
  end

  @doc """
  Get current theme name
  """

  def theme do
    Application.get_env(:ex_admin, :theme, @default_theme)
  end

  # def theme_model, do: theme.__struct__

  def theme_name(conn) do
    conn.assigns.theme.name
  end

  defp action_button(conn, defn, name, page, action, actions, id \\ nil) do
    if action in actions do
      if ExAdmin.Utils.authorized_action?(conn, action, defn) do
        [action_link(conn, name, action, id)]
      else
        []
      end
    else
      []
    end ++
    if button = get_custom_action(page, actions) do
      {fun, _} = Code.eval_quoted button, [id: id], __ENV__
      if is_function(fun, 1), do: [text(fun.(id) |> elem(1))], else: []
      if is_function(fun, 0), do: [text(fun.() |> elem(1))], else: []
    end
  end

  @doc false
  def get_custom_action(action, actions) do
    Enum.find_value actions, fn(x) ->
      case x do
        nil -> nil
        {^action, val} -> val
        _ -> nil
      end
    end
  end

  defp action_link(conn, name, :delete, id) do
    {button_name(name, :delete),
      [href: ExAdmin.Utils.get_route_path(conn, :delete, id),
        "data-confirm": Utils.confirm_message,
        "data-remote": true,
        "data-method": :delete, rel: :nofollow]}
    # a(href: ExAdmin.Utils.get_route_path(conn, :delete, id),
    #     "data-confirm": Utils.confirm_message,
    #     "data-csrf": Plug.CSRFProtection.get_csrf_token,
    #     "data-method": :delete, rel: :nofollow ) do
    #   button_name(name, :delete)
    #   |> button(class: "btn btn-danger")
    # end
  end
  defp action_link(conn, name, action, id) do
    {button_name(name, action),
      [href: ExAdmin.Utils.get_route_path(conn, action, id)]}
    # a(href: ExAdmin.Utils.get_route_path(conn, action, id)) do
    #   button_name(name, action)
    #   |> button(class: "btn btn-primary")
    # end
  end

  defp button_name(name, :destroy), do: button_name(name, :delete)
  defp button_name(name, action) do
    "#{humanize action} #{name}"
  end

  @doc false
  def has_action?(conn, defn, action) do
    if ExAdmin.Utils.authorized_action?(conn, action, defn),
      do: _has_action?(defn, action), else: false
  end

  defp _has_action?(defn, action) do
    except = Keyword.get defn.actions, :except, []
    only = Keyword.get defn.actions, :only, []
    cond do
      action in defn.actions -> true
      action in only -> true
      action in except -> false
      true -> false
    end
  end

end
