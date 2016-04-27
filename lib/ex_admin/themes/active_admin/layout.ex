defmodule ExAdmin.Theme.ActiveAdmin.Layout do
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import ExAdmin.Navigation
  import ExAdmin.ViewHelpers
  use Xain

  def link_to_active(conn, name, path, id, _opts \\ []) do
    active_class = if link_active?(conn, path), do: "current", else: ""

    content_tag :li, id: id, class: active_class  do
      content_tag :a, name, href: path
    end
  end
  
  def theme_selector do
    Application.get_env(:ex_admin, :theme_selector)
    |> Enum.with_index
    |> theme_selector
  end

  defp theme_selector(nil), do: ""
  defp theme_selector(options) do
    current = Application.get_env(:ex_admin, :theme)
    content_tag :select, id: "theme-selector" do
      for {{name, theme}, inx} <- options do
        selected = if current == theme, do: [selected: "selected"], else: []
        content_tag(:option, name, [value: "#{inx}"] ++ selected )
      end
    end 
  end

  def render_breadcrumbs([]), do: nil
  def render_breadcrumbs(list) do
    span(".breadcrumb") do
      Enum.each list, fn({link, name}) -> 
        a(name, href: link)
        span(".breadcrumb_sep /")
      end
    end
  end

  def wrap_title_bar(fun) do
    div("#title_bar.title_bar") do
      fun.()
    end
  end

  def title_bar(conn, resource) do
    markup do
      div("#title_bar.title_bar") do
        title_bar_left(conn, resource)
        title_bar_right(conn)
      end
    end
  end

  def title_bar_left(conn, resource) do
    div("#titlebar_left") do
      render_breadcrumbs ExAdmin.BreadCrumb.get_breadcrumbs(conn, resource)
      h1("#page_title #{page_title(conn, resource)}")
    end
  end
  defp title_bar_right(conn) do
    div("#titlebar_right") do
      ExAdmin.get_title_actions(conn)
    end
  end
end
