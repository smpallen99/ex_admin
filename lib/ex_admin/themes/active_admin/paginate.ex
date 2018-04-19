defmodule ExAdmin.Theme.ActiveAdmin.Paginate do
  @moduledoc false
  import ExAdmin.Paginate
  use Xain

  def wrap_pagination1(fun) do
    nav ".pagination" do
      fun.()
    end
  end

  def wrap_pagination2(fun) do
    div ".pagination_information" do
      fun.()
    end
  end

  def build_item(_, {:current, num}) do
    span(".current.page #{num}")
  end

  def build_item(_, {:gap, _}) do
    span ".page.gap" do
      text("... ")
    end
  end

  def build_item(link, {item, num}) when item in [:first, :prev, :next, :last] do
    span ".#{item}" do
      a("#{special_name(item)}", href: "#{link}&page=#{num}")
    end
  end

  def build_item(link, {item, num}) do
    span ".#{item}" do
      a("#{num}", href: "#{link}&page=#{num}")
    end
  end
end
