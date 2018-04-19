defmodule ExAdmin.Paginate do
  @moduledoc false
  use Xain
  import ExAdmin.Theme.Helpers
  import ExAdmin.Gettext

  def paginate(_, nil, _, _, _, _, _), do: []

  def paginate(link, page_number, page_size, total_pages, record_count, name) do
    markup do
      theme_module(Paginate).wrap_pagination1(fn ->
        if total_pages > 1 do
          for item <- items(page_number, page_size, total_pages) do
            theme_module(Paginate).build_item(link, item)
          end
        end
      end)

      theme_module(Paginate).wrap_pagination2(fn ->
        record_number = (page_number - 1) * page_size + 1

        display_pagination(
          name,
          (page_number - 1) * page_size + 1,
          page_size,
          record_count,
          record_number + page_size - 1
        )
      end)
    end
  end

  defp display_pagination(name, _record_number, 1, record_count, _) do
    pagination_information(name, record_count)
  end

  defp display_pagination(name, record_number, _page_size, record_count, last_number)
       when last_number < record_count do
    pagination_information(name, record_number, last_number, record_count)
  end

  defp display_pagination(name, record_number, _page_size, record_count, _) do
    pagination_information(name, record_number, record_count, record_count)
  end

  def pagination_information(name, record_number, record_number, record_count) do
    markup do
      text(gettext("Displaying") <> Inflex.singularize(" #{name}") <> " ")
      b("#{record_number}")
      text(" " <> gettext("of") <> " ")
      b("#{record_count}")
      text(" " <> gettext("in total"))
    end
  end

  def pagination_information(name, record_number, last, record_count) do
    markup do
      text(gettext("Displaying %{name}", name: name) <> " ")
      b("#{record_number}&nbsp;-&nbsp;#{last}")
      text(" " <> gettext("of") <> " ")
      b("#{record_count}")
      text(" " <> gettext("in total"))
    end
  end

  def pagination_information(name, total) do
    markup do
      text(gettext("Displaying") <> " ")
      b(gettext("all %{total}", total: total))
      text(" #{name}")
    end
  end

  def special_name(:first), do: gettext("« First")
  def special_name(:prev), do: gettext("‹ Prev")
  def special_name(:next), do: gettext("Next ›")
  def special_name(:last), do: gettext("Last »")

  def window_size, do: 7

  def items(page_number, page_size, total_pages) do
    prefix_links(page_number)
    |> prefix_gap
    |> links(page_number, page_size, total_pages)
    |> postfix_gap
    |> postfix_links(page_number, total_pages)
  end

  def prefix_links(1), do: []

  def prefix_links(page_number) do
    prev = if page_number > 1, do: page_number - 1, else: 1
    [first: 1, prev: prev]
  end

  def prefix_gap(acc) do
    acc
  end

  def postfix_gap(acc), do: acc

  def links(acc, page_number, _page_size, total_pages) do
    half = Kernel.div(window_size(), 2)

    before =
      cond do
        page_number == 1 -> 0
        page_number - half < 1 -> 1
        true -> page_number - half
      end

    aftr =
      cond do
        before + half >= total_pages -> total_pages
        page_number + window_size() >= total_pages -> total_pages
        true -> page_number + half
      end

    before_links =
      if before > 0 do
        for x <- before..(page_number - 1), do: {:page, x}
      else
        []
      end

    after_links =
      if page_number < total_pages do
        for x <- (page_number + 1)..aftr, do: {:page, x}
      else
        []
      end

    pregap = if before != 1 and page_number != 1, do: [gap: true], else: []
    postgap = if aftr != total_pages and page_number != total_pages, do: [gap: true], else: []
    acc ++ pregap ++ before_links ++ [current: page_number] ++ after_links ++ postgap
  end

  def postfix_links(acc, page_number, total_pages) do
    if page_number == total_pages do
      acc
    else
      acc ++ [next: page_number + 1, last: total_pages]
    end
  end
end
