defmodule ExAdmin.ResourceTitleActions do
  alias ExAdmin.Utils
  @doc false
  def default(%Plug.Conn{params: params} = conn, %{resource_model: resource_model} = defn) do
    singular = Utils.displayable_name_singular(conn) |> Utils.titleize
    actions = defn.actions
    case Utils.action_name(conn) do
      :show ->
        id = Map.get(params, "id")
        Enum.reduce([:edit, :new, :delete], [], fn(action, acc) ->
          if Utils.authorized_action?(conn, action, resource_model) do
            [{action, action_button(conn, defn, singular, :show, action, actions, id)}|acc]
          else
            acc
          end
        end)
        |> add_custom_actions(:show, actions, conn, resource_model, id)
        |> Enum.reverse
      action when action in [:index, :edit] ->
        if Utils.authorized_action?(conn, action, resource_model) do
          [{:new, action_button(conn, defn, singular, action, :new, actions)}]
        else
          []
        end
        |> add_custom_actions(action, actions, conn, resource_model)
        |> Enum.reverse
      _ ->
        []
    end
  end

  @doc false
  def action_button(conn, defn, name, _page, action, actions, id \\ nil) do
    if action in actions do
      if Utils.authorized_action?(conn, action, defn) do
        action_name = defn.action_labels[action] || Utils.humanize(action)
        [action_link(conn, "#{action_name} #{name}", action, id)]
      else
        []
      end
    else
      []
    end
  end

  defp add_custom_actions(acc, action, actions, conn, resource_model, id \\ nil)
  defp add_custom_actions(acc, _action, [], _conn, _resource_model, _id), do: acc
  defp add_custom_actions(acc, action, [{action, custom_action_name, button} | actions], conn, resource_model, id) do
    %{action: custom_action_name, id: id}
    |> Utils.authorized_action?(action, resource_model)
    |> eval_custom_function(button, id, acc)
    |> add_custom_actions(action, actions, conn, resource_model, id)
  end
  defp add_custom_actions(acc, action, [{action, button} | actions], conn, resource_model, id) do
    conn
    |> Utils.authorized_action?(action, resource_model)
    |> eval_custom_function(button, id, acc)
    |> add_custom_actions(action, actions, conn, resource_model, id)
  end
  defp add_custom_actions(acc, action, [_|actions], conn, resource_model, id) do
    add_custom_actions(acc, action, actions, conn, resource_model, id)
  end

  defp eval_custom_function(false, _button, _id, acc), do: acc
  defp eval_custom_function(true, button, id, acc) do
    import ExAdmin.ViewHelpers
    endpoint()  # remove the compiler warning
    {fun, _} = Code.eval_quoted button, [id: id], __ENV__
    cond do
      is_function(fun, 1) -> [fun.(id) | acc]
      is_function(fun, 0) -> [fun.() | acc]
      true                -> acc
    end
  end

  defp action_link(conn, name, :delete, _id) do
    {name,
      [href: Utils.admin_resource_path(conn, :destroy),
        "data-confirm": Utils.confirm_message,
        "data-method": :delete, rel: :nofollow]}
  end
  defp action_link(conn, name, action, _id) do
    {name, [href: Utils.admin_resource_path(conn, action)]}
  end
end
