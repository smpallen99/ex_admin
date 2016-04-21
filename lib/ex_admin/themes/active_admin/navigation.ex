defmodule ExAdmin.Theme.ActiveAdmin.Navigation do
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import ExAdmin.Navigation

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
end
