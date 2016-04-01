defmodule ExAdmin.Navigation do
  @moduledoc false
  require Logger
  import ExAdmin.Utils
  use Xain

  def nav_view(conn) do
    markup do
      registered = ExAdmin.get_all_registered 
      |> Enum.map(fn({_, resource}) -> resource end)
      |> Enum.filter(fn(%{menu: menu}) -> menu[:none] != true end)
      |> Enum.filter(fn(%{menu: menu} = defn) -> 
        case menu[:if] do
          nil -> true
          fun when is_function(fun, 2) -> fun.(conn, defn)
          fun -> fun.(conn)
        end
      end)
      |> Enum.sort(fn(%{menu: menu1}, %{menu: menu2}) -> 
        menu1[:priority] < menu2[:priority]
      end)
      # ul(".header-item#tabs") do
      div ".callapse.navbar-callapse.pull-left#navbar-callapse" do
        ul(".nav.navbar-nav") do
          for resource <- registered do
            nav_link(conn, resource)
          end
        end
      end
    end
  end
  def nav_link(conn, %{controller: controller, type: :page, page_name: _page_name} = registered) do
    controller_name = controller_name(controller)
    # path = get_route_path(resource_model, :index)
    path = "/admin/dashboard"
    menu = Map.get registered, :menu, %{}
    name = Map.get menu, :label, (controller_name |> titleize |> Inflex.pluralize)
    link_to_active conn, name, path, (Inflex.parameterize(controller_name, "_") |> Inflex.pluralize)
  end
  def nav_link(conn, %{controller: controller, resource_model: resource_model} = registered) do
    controller_name = controller_name(controller)
    path = get_route_path(resource_model, :index)
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
