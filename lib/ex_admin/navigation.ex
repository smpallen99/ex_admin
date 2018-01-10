defmodule ExAdmin.Navigation do
  @moduledoc false
  require Logger
  import ExAdmin.Utils
  import ExAdmin.Theme.Helpers
  use Xain

  def nav_view(conn, opts \\ []) do
    registered =
      ExAdmin.get_all_registered()
      |> Enum.map(fn {_, resource} -> resource end)
      |> Enum.filter(fn %{menu: menu} -> menu[:none] != true end)
      |> Enum.filter(fn %{menu: menu} = defn ->
        case menu[:if] do
          nil -> true
          fun when is_function(fun, 2) -> fun.(conn, defn)
          fun -> fun.(conn)
        end
      end)
      |> Enum.filter(fn defn -> ExAdmin.Utils.authorized_action?(conn, :index, defn) end)
      |> Enum.sort(fn %{menu: menu1}, %{menu: menu2} ->
        menu1[:priority] < menu2[:priority]
      end)

    for resource <- registered do
      nav_link(conn, resource, opts)
    end
  end

  def nav_link(
        conn,
        %{controller: controller, type: :page, page_name: page_name} = registered,
        opts
      ) do
    controller_name = controller_name(controller)
    menu = Map.get(registered, :menu, %{})
    path = Map.get(menu, :url, admin_path(:page, [String.downcase(page_name)]))
    name = Map.get(menu, :label, controller_name |> titleize |> Inflex.pluralize())

    theme_module(conn, Layout).link_to_active(
      conn,
      name,
      path,
      Inflex.parameterize(controller_name, "_") |> Inflex.pluralize(),
      opts
    )
  end

  def nav_link(conn, %{controller: controller, resource_model: resource_model} = registered, opts) do
    controller_name = controller_name(controller)
    path = admin_resource_path(resource_model, :index)
    menu = Map.get(registered, :menu, %{})
    name = Map.get(menu, :label, controller_name |> titleize |> Inflex.pluralize())

    theme_module(conn, Layout).link_to_active(
      conn,
      name,
      path,
      Inflex.parameterize(controller_name, "_") |> Inflex.pluralize(),
      opts
    )
  end

  def get_registered_resources do
    [UcxCallout.Contact, UcxCallout.Categories]
  end

  def link_active?(conn, path) do
    path = strip_path(path)

    conn.path_info
    |> Enum.join("/")
    |> String.match?(~r/^#{path}/)
  end

  def strip_path(path) do
    String.replace(path, ~r/(^http:\/\/)|(^\/)/, "")
  end
end
