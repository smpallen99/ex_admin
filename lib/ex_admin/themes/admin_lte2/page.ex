defmodule ExAdmin.Theme.AdminLte2.Page do
  @moduledoc false
  use Xain

  def columns(cols) do
    count = Kernel.div 12, Enum.count(cols)
    for {:safe, html} <- cols do
      markup :nested do
        div html, class: "col-lg-#{count}"
      end
      |> elem(1) |> raw
    end
  end
end
