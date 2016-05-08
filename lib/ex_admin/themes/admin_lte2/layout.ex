defmodule ExAdmin.Theme.AdminLte2.Layout do
  import ExAdmin.Navigation
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  use Xain
  require Logger

  def link_to_active(conn, name, path, id, opts \\ []) do
    wrapper = Keyword.get(opts, :wrapper, :li)
    # html_opts = Keyword.get(opts, :html_opts, [])
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

  def theme_selector? do
    not is_nil(Application.get_env(:ex_admin, :theme_selector))
  end
  def theme_selector do
    Application.get_env(:ex_admin, :theme_selector)
    |> Enum.with_index
    |> theme_selector
  end

  defp theme_selector(nil), do: ""
  defp theme_selector(options) do
    current = Application.get_env(:ex_admin, :theme)
    for {{name, theme}, inx} <- options do
      active = if current == theme, do: "active", else: ""
      content_tag :li, class: active  do
        content_tag :a, name, href: "#", "data-theme": "#{inx}", class: "theme-selector"
      end
    end
  end

  def render_breadcrumbs([]), do: nil
  def render_breadcrumbs(list) do
    ol(".breadcrumb") do
      Enum.each list, fn({link, name}) ->
        li do
          a(name, href: link)
        end
      end
    end
  end

  def wrap_title_bar(fun) do
    section("#title_bar.content-header") do
      fun.()
    end
  end

  def logo_mini do
    default = "Ex<b>A</b>"
    Application.get_env(:ex_admin, :logo_mini, default)
    |> Phoenix.HTML.raw
  end

  def logo_full do
    default = "Ex<b>Admin</b>"
    Application.get_env(:ex_admin, :logo_full, default)
    |> Phoenix.HTML.raw
  end

  def sidebar_view(conn, {name, opts, {mod, fun}}, resource) do
    box_attributes = Keyword.get(opts, :box_attributes, ".box.box-primary")
    header_attributes = Keyword.get(opts, :header_attributes, ".box-header.with-border")
    body_attributes = Keyword.get(opts, :body_attributes, ".box-body")
    markup do
      div box_attributes do
        div header_attributes do
          h3 ".box-title #{name}"
        end
        div body_attributes do
          case apply mod, fun, [conn, resource] do
            {_, rest} -> text rest
            :ok       -> ""
            other     -> text other
          end
        end
      end
    end
  end
end
