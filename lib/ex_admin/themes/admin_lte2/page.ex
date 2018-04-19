defmodule ExAdmin.Theme.AdminLte2.Page do
  @moduledoc false
  use Xain

  def columns(cols) do
    count = Kernel.div(12, Enum.count(cols))

    for html <- cols do
      div(html, class: "col-lg-#{count}")
    end
  end
end
