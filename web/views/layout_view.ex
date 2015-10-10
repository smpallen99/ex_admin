defmodule ExAdmin.LayoutView do
  @moduledoc false
  use ExAdmin.Web, :view
  import ExAdmin.ViewHelpers

  def site_title do
    case Application.get_env(:ex_admin, :module) |> Module.split do
      [_, title | _] -> title
      [title] -> title
      _ -> "ExAdmin"
    end
  end

end
