defmodule ExAdmin.BreadCrumb do
  @moduledoc false
  require Logger

  def get_breadcrumbs(conn, resource) do
    defn = conn.assigns.defn

    get_breadcrumbs(
      conn,
      resource,
      defn,
      Map.get(defn, :page_name),
      conn.private[:phoenix_action]
    )
  end

  defp get_breadcrumbs(conn, _resource, _, nil, :index) do
    case conn.path_info do
      [admin | _] -> [{admin_link(admin), admin}]
      _ -> []
    end
  end

  defp get_breadcrumbs(conn, _resource, defn, nil, action)
       when action in [:new, :show, :create] do
    case conn.path_info do
      [admin, name | _] ->
        admin_link = admin_link(admin)
        [{admin_link, admin}, {resource_link(admin_link, name), get_label(defn, name)}]

      _ ->
        []
    end
  end

  defp get_breadcrumbs(conn, resource, defn, nil, action) when action in [:edit, :update] do
    id =
      case resource.__struct__.__schema__(:primary_key) do
        [key | _] -> Map.get(resource, key)
        _ -> nil
      end

    display_name = ExAdmin.Helpers.display_name(resource)

    get_breadcrumbs(conn, resource, defn, nil, :new) ++
      case conn.path_info do
        [admin, name | _] ->
          resource_link =
            admin_link(admin)
            |> resource_link(name)

          [{resource_link <> "/#{id}", get_name(id, display_name)}]

        _ ->
          []
      end
  end

  defp get_breadcrumbs(_conn, _resource, _, _, _), do: []

  defp get_name(_id, name) when not is_nil(name), do: to_string(name)
  defp get_name(id, _), do: to_string(id)

  defp get_label(defn, name) do
    case Map.get(defn, :menu) do
      %{label: label} -> label
      _ -> name
    end
  end

  defp admin_link(admin), do: "/" <> admin
  defp resource_link(admin_link, name), do: admin_link <> "/" <> name
end
