defmodule ExAdmin.Theme.AdminLte2.Paginate do
  @moduledoc false
  import ExAdmin.Paginate
  use Xain

  def wrap_pagination1(fun) do
    ul ".pagination.pagination-sm.no-margin.pull-right" do
      fun.()
    end
  end

  def wrap_pagination2(fun) do
    div ".pagination_information" do
      fun.()
    end
  end

  def build_item(_, {:current, num}) do
    li ".active" do
      a("#{num}", href: "#")
    end
  end

  def build_item(_, {:gap, _}) do
    li ".page.gap" do
      span do
        text(" ...")
      end
    end
  end

  def build_item(link, {item, num}) when item in [:first, :prev, :next, :last] do
    li do
      a("#{special_name(item)}", href: "#{link}&page=#{num}")
    end
  end

  def build_item(link, {_item, num}) do
    li do
      a("#{num}", href: "#{link}&page=#{num}")
    end
  end
end
