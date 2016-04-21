defmodule ExAdmin.Theme.AdminLte2.Navigation do
  import ExAdmin.Navigation 
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]

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
        content_tag :a, name, href: "/admin/select_theme/#{inx}"
      end
    end
  end
end
