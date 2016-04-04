defmodule ExAdmin.Navigation do
  @moduledoc false
  require Logger
  import ExAdmin.Utils
  use Xain
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]

  def nav_view(conn, opts \\ []) do
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

    for resource <- registered do
      nav_link(conn, resource, opts)
    end
  end

  def nav_link(conn, %{controller: controller, type: :page, page_name: _page_name} = registered, opts) do
    controller_name = controller_name(controller)
    # path = get_route_path(resource_model, :index)
    path = "/admin/dashboard"
    menu = Map.get registered, :menu, %{}
    name = Map.get menu, :label, (controller_name |> titleize |> Inflex.pluralize)
    link_to_active conn, name, path, (Inflex.parameterize(controller_name, "_") |> Inflex.pluralize), opts
  end
  def nav_link(conn, %{controller: controller, resource_model: resource_model} = registered, opts) do
    controller_name = controller_name(controller)
    path = get_route_path(resource_model, :index)
    menu = Map.get registered, :menu, %{}
    name = Map.get menu, :label, (controller_name |> titleize |> Inflex.pluralize)
    link_to_active conn, name, path, (Inflex.parameterize(controller_name, "_") |> Inflex.pluralize), opts
  end

  def get_registered_resources do
    [UcxCallout.Contact, UcxCallout.Categories]
  end

  def link_to_active(conn, name, path, id, opts \\ []) do
    wrapper = Keyword.get(opts, :wrapper, :li)
    html_opts = Keyword.get(opts, :html_opts, [])
    active_class = Keyword.get(opts, :active_class, "active")
    active_class = if link_active?(conn, path), do: active_class, else: ""
    icon = if Path.basename(path) == "dashboard" do
      content_tag :i, "", class: "fa fa-dashboard"
    else
      content_tag :i, String.at(name, 0), class: "nav-label label label-info"
    end
    name_span = content_tag :span, name
    a_tag = content_tag :a, [icon, name_span], href: path
    if wrapper == :none do
      a_tag
    else 
      content_tag wrapper, id: id, class: active_class  do
        a_tag
      end
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
