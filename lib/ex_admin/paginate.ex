defmodule ExAdmin.Paginate do
  use Xain

  def paginate(_, nil, _, _, _, _, _), do: []
  def paginate(link, page_number, page_size, total_pages, record_count, name) do
    nav ".pagination" do
      if total_pages > 1 do
        for item <- items(page_number, page_size, total_pages) do
          build_item link, item
        end
      end
    end
    div ".pagination_information" do
      record_number = (page_number - 1) * page_size + 1
      case record_number + page_size - 1 do
        val when val < record_count -> 
          pagination_information(name, record_number, val, record_count)
        _ -> 
          pagination_information(name, record_count)
      end
    end
  end

  def pagination_information(name, record_number, last, record_count) do
    text "Displaying #{name} "
    b "#{record_number}&nbsp;-&nbsp;#{last}"
    text " of "
    b "#{record_count}"
    text " in total"
  end

  def pagination_information(name, total) do
    text "Displaying "
    b "all #{total}"
    text " #{name}"
  end


  def build_item(_, {:current, num}) do
    span ".current.page #{num}"
  end
  def build_item(_, {:gap, _}) do
    span ".page.gap" do
      text "... "
    end
  end
  
  def build_item(link, {item, num}) when item in [:first, :prev, :next, :last] do
    span ".#{item}" do
      a "#{special_name item}", href: "#{link}&page=#{num}"
    end
  end

  def build_item(link, {item, num}) do
    span ".#{item}" do
      a "#{num}", href: "#{link}&page=#{num}"
    end
  end

  def special_name(:first), do: "« First"
  def special_name(:prev), do: "‹ Prev"
  def special_name(:next), do: "Next ›"
  def special_name(:last), do: "Last »"

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
    half = Kernel.div window_size, 2
    before = cond do
      page_number == 1 -> 0
      page_number - half < 1 -> 1
      true -> page_number - half
    end
    aftr = cond do
      before + half >= total_pages -> total_pages
      page_number + window_size >= total_pages -> total_pages
      true -> page_number + half 
    end
    before_links = if before > 0 do 
      for x <- before..(page_number - 1), do: {:page, x}
    else
      []
    end
    after_links = if page_number < total_pages do
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
