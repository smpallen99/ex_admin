defmodule ExAdmin.LayoutView do
  @moduledoc false
  use ExAdmin.Web, :view
  import ExAdmin.ViewHelpers
  import ExAdmin.Authentication

  def site_title do
    case Application.get_env(:ex_admin, :module) |> Module.split do
      [_, title | _] -> title
      [title] -> title
      _ -> "ExAdmin"
    end
  end

  def check_for_sidebars(conn, filters, defn) do
    require Logger
    if is_nil(filters) and not ExAdmin.Sidebar.sidebars_visible?(conn, defn) do
      {false, "without_sidebar"}
    else
      {true, "with_sidebar"}
    end
  end
end
