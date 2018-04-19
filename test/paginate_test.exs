defmodule ExAdmin.PaginateTest do
  use ExUnit.Case
  alias ExAdmin.Paginate

  test "pagination_information name total" do
    assert Paginate.pagination_information("Contacts", 10) == "Displaying <b>all 10</b> Contacts"
  end

  test "pagination_information/4" do
    assert Paginate.pagination_information("Contacts", 1, 1, 10) ==
             "Displaying Contact <b>1</b> of <b>10</b> in total"
  end

  test "pagination_information last" do
    assert Paginate.pagination_information("Contacts", 1, 10, 100) ==
             "Displaying Contacts <b>1&nbsp;-&nbsp;10</b> of <b>100</b> in total"
  end

  @link "/admin/contacts?order="
  test "paginate fist page links" do
    html = Paginate.paginate(@link, 1, 10, 11, 103, "Contacts")
    items = Floki.find(html, "ul.pagination li")
    assert Enum.count(items) == 7
    assert Floki.find(hd(items), "li a") |> Floki.text() == "1"
    items = Enum.reverse(items)

    assert Floki.find(hd(items), "li a") |> Floki.attribute("href") ==
             ["/admin/contacts?order=&page=11"]
  end

  test "paginate fist page information" do
    html = Paginate.paginate(@link, 1, 10, 11, 103, "Contacts")
    text = Floki.find(html, "div") |> Floki.text()
    assert text =~ "Displaying Contacts"
    assert text =~ "1 - 10 of 103 in total"
  end
end
