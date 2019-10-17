defmodule ExAdmin.Theme.ActiveAdmin.Page do
  @moduledoc false
  use Xain

  def columns(cols) do
    col_count = Enum.count(cols)
    count = Kernel.div(12, col_count)

    markup do
      div ".columns" do
        for {html, inx} <- Enum.with_index(cols) do
          style =
            "width: #{100 / (12 / count) - 2}%;" <>
              if inx < col_count - 1, do: " margin-right: 2%;", else: ""

          div(html, class: "column", style: style)
        end

        div("", style: "clear:both;")
      end
    end
  end
end
