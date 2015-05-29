defmodule ExAdmin.Navigation do
  require Logger
  import ExAdmin.Utils
  use Xain

  def nav_view(conn) do
    markup do
      registered = ExAdmin.get_all_registered 
      |> Enum.map(fn({_, resource}) -> resource end)
      |> Enum.filter(fn(%{menu: menu}) -> menu[:none] != true end)
      |> Enum.filter(fn(%{menu: menu}) -> 
        case menu[:if] do
          nil -> true
          fun -> fun.(conn)
        end
      end)
      |> Enum.sort(fn(%{menu: menu1}, %{menu: menu2}) -> 
        menu1[:priority] < menu2[:priority]
      end)
      ul(".header-item#tabs") do
        for resource <- registered do
          nav_link(conn, resource)
        end
      end
    end
  end
  def nav_link(conn, %{controller: controller, resource_name: resource_name} = registered) do
    controller_name = controller_name(controller)
    path = get_route_path(resource_name, :index)
    menu = Map.get registered, :menu, %{}
    name = Map.get menu, :label, (controller_name |> titleize |> Inflex.pluralize)
    link_to_active conn, name, path, (Inflex.parameterize(controller_name, "_") |> Inflex.pluralize)
  end

  def get_registered_resources do
    [UcxCallout.Contact, UcxCallout.Categories]
  end

  def link_to_active(conn, name, path, id, _opts \\ []) do
    active_class = if link_active?(conn, path), do: "current", else: ""
    li(id: id, class: active_class) do
      a(name, href: path)
    end
  end

  defp link_active?(conn, path) do
    path = strip_path path
    conn.path_info
    |> Enum.join("/")
    |> String.match?(~r/^#{path}/)
  end
  def strip_path(path) do
    String.replace(path, ~r/(^http:\/\/)|(^\/)/, "")
  end
end
