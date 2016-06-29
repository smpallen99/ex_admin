defmodule ExAdmin.LayoutView do
  @moduledoc false
  use ExAdmin.Web, :view

  def favicon do
    if File.exists? "priv/static/favicon.ico" do
      Phoenix.HTML.Tag.tag :link, rel: "icon", href: "/favicon.ico", type: "image/x-icon"
    else
      ""
    end
  end

  def site_title do
    case Application.get_env(:ex_admin, :title) do
      nil ->
        case Application.get_env(:ex_admin, :module) |> Module.split do
          [_, title | _] -> title
          [title] -> title
          _ -> "ExAdmin"
        end
      title -> title
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


  def check_for_sidebars(conn, filters, defn) do
    if (is_nil(filters) or filters == false) and not ExAdmin.Sidebar.sidebars_visible?(conn, defn) do
      {false, "without_sidebar"}
    else
      {true, "with_sidebar"}
    end
  end

  def admin_static_path(conn, path) do
    static_path conn, Path.join(["/", "themes", ExAdmin.theme.name, path])
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

end
