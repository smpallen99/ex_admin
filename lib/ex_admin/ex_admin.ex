defmodule ExAdmin do
  require Logger
  use Xain
  alias ExAdmin.Utils
  import ExAdmin.Utils, only: [base_name: 1, titleize: 1, humanize: 1]
  require ExAdmin.Register

  @filename "/tmp/ex_admin_registered" 
  Code.ensure_compiled ExAdmin.Register

  Module.register_attribute __MODULE__, :registered, accumulate: true, persist: true

  defmacro __using__(_) do
    quote do
      use ExAdmin.Index
      import unquote(__MODULE__)
    end
  end

  def registered, do: Application.get_env(:ex_admin, :modules, [])

  def put_data(key, value) do
    Agent.update __MODULE__, &(Map.put(&1, key, value))
  end

  def get_data(key) do
    Agent.get __MODULE__, &(Map.get(&1, key))
  end

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
  def get_registered_resource(name) do
    apply(name, :__struct__, [])
  end

  def get_registered do
    for reg <- registered do
      get_registered_resource(reg)
    end
  end
  def get_registered(resource_model) do
    get_all_registered
    |> Keyword.get(resource_model)
  end

  def get_registered_by_controller_route!(name) do
    res = get_registered_by_controller_route(name) 
    if res == %{}, do: throw("Unknown Resource"), else: res
  end

  def get_registered_by_controller_route(%Plug.Conn{params: params}) do
    get_registered_by_controller_route params["resource"]
  end
  def get_registered_by_controller_route(path_info) when is_list(path_info) do
    case path_info do
      ["admin", route | _] -> route
      _ -> ""
    end
    |> get_registered_by_controller_route
  end

  def get_registered_by_controller_route(route) do
    Enum.find get_registered, %{}, &(Map.get(&1, :controller_route) == route)
  end

  def get_controller_path(%{} = resource) do
    get_controller_path Map.get(resource, :__struct__)
  end
  def get_controller_path(resource_model) when is_atom(resource_model) do
    get_all_registered 
    |> Keyword.get(resource_model, %{})
    |> Map.get(:controller_route)
  end

  def get_title_actions(%Plug.Conn{private: _private, path_info: path_info} = conn) do
    defn = get_registered_by_controller_route(path_info)
    fun = defn |> Map.get(:title_actions)
    fun.(conn, defn)
  end

  def get_title_actions(name) do
    case get_registered(name) do
      nil -> 
        &__MODULE__.default_page_title_actions/2
      %{title_actions: actions} -> 
        actions
    end
  end

  def get_name_from_controller(controller) when is_atom(controller) do
    get_all_registered
    |> Enum.find_value(fn({name, %{controller: c_name}}) -> 
      if c_name == controller, do: name 
    end) 
  end

  def default_resource_title_actions(%Plug.Conn{params: params} = conn, %{resource_model: _resource_model} = defn) do
    # Logger.warn "action name: #{inspect Utils.action_name(conn)}"
    singular = ExAdmin.Utils.displayable_name_singular(conn) |> titleize
    actions = defn.actions
    case Utils.action_name(conn) do
      :show -> 
        id = Map.get(params, "id")
        |> String.to_integer
        div(".action_items") do
          for action <- [:edit, :new, :delete], 
            do: action_button(conn, defn, singular, :show, action, actions, id)
        end
        
      action when action in [:index, :edit] -> 
        div(".action_items") do
          action_button(conn, defn, singular, action, :new, actions)
        end

      _ -> 
        div(".action_items")
    end
  end

  def default_page_title_actions(_conn, _) do
    div(".action_items")
  end

  defp action_button(conn, defn, name, page, action, actions, id \\ nil) do
    if action in actions do
      if ExAdmin.Utils.authorized_action?(conn, action, defn) do
        span(".action_item") do
          action_link(conn, name, action, id)
        end
      end
    end
    button = get_custom_action(page, actions) 
    if button do
      span(".action_item") do
        {fun, _} = Code.eval_quoted button, [id: id], __ENV__
        if is_function(fun, 1), do: text(fun.(id) |> elem(1))
        if is_function(fun, 0), do: text(fun.() |> elem(1))
      end
    end
  end

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
    button_name(name, :delete)
    |> a(href: ExAdmin.Utils.get_route_path(conn, :delete, id),
        "data-confirm": Utils.confirm_message, 
        "data-method": :delete, rel: :nofollow )
  end
  defp action_link(conn, name, action, id) do
    button_name(name, action)
    |> a(href: ExAdmin.Utils.get_route_path(conn, action, id))
  end

  defp button_name(name, :destroy), do: button_name(name, :delete)
  defp button_name(name, action) do
    "#{humanize action} #{name}"
  end

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
