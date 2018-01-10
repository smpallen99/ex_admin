defmodule ExAdmin.Theme.ActiveAdmin.Layout do
  @moduledoc false
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import ExAdmin.Navigation
  import ExAdmin.ViewHelpers
  require Logger
  use Xain

  def link_to_active(conn, name, path, id, _opts \\ []) do
    active_class = if link_active?(conn, path), do: "current", else: ""

    content_tag :li, id: id, class: active_class do
      content_tag(:a, name, href: path)
    end
  end

  def theme_selector do
    case Application.get_env(:ex_admin, :theme_selector) do
      nil ->
        ""

      list ->
        list
        |> Enum.with_index()
        |> theme_selector
    end
  end

  defp theme_selector(nil), do: ""

  defp theme_selector(options) do
    current = Application.get_env(:ex_admin, :theme)

    content_tag :select, id: "theme-selector", style: "float: right;" do
      for {{name, theme}, inx} <- options do
        selected = if current == theme, do: [selected: "selected"], else: []
        content_tag(:option, name, [value: "#{inx}"] ++ selected)
      end
    end
  end

  def render_breadcrumbs([]), do: nil

  def render_breadcrumbs(list) do
    span ".breadcrumb" do
      Enum.each(list, fn {link, name} ->
        a(name, href: link)
        span(".breadcrumb_sep /")
      end)
    end
  end

  def wrap_title_bar(fun) do
    div "#title_bar.title_bar" do
      fun.()
    end
  end

  def title_bar(conn, resource) do
    markup safe: true do
      div "#title_bar.title_bar" do
        title_bar_left(conn, resource)
        title_bar_right(conn)
      end
    end
  end

  def title_bar_left(conn, resource) do
    div "#titlebar_left" do
      render_breadcrumbs(ExAdmin.BreadCrumb.get_breadcrumbs(conn, resource))
      h2("#page_title #{page_title(conn, resource)}")
    end
  end

  defp title_bar_right(conn) do
    require Logger

    div "#titlebar_right" do
      div ".action_items" do
        for {_item, [{text, opts} | _]} <- ExAdmin.get_title_actions(conn) do
          span ".action_item" do
            a(text, opts)
          end
        end
      end
    end
  end

  def sidebar_view(conn, {name, _opts, {mod, fun}}, resource) do
    markup safe: true do
      div "#filters_sidebar_sectionl.sidebar_section.panel" do
        h3("#{name}")

        div ".panel_contents" do
          case apply(mod, fun, [conn, resource]) do
            {_, rest} -> text(rest)
            :ok -> ""
            other -> text(other)
          end
        end
      end
    end
  end
end
