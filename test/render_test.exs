defmodule ExAdminTest.Render do
  use ExUnit.Case, async: true
  alias ExAdmin.Render

  test "string" do
    assert Render.to_string("test") == "test"
  end

  test "integer" do
    assert Render.to_string(123) == "123"
  end

  test "float" do
    assert Render.to_string(10.99) == "10.99"
  end

  test "atom" do
    assert Render.to_string(:test) == "test"
  end

  test "list" do
    assert Render.to_string([:one, :two]) == ~s/["one","two"]/
  end

  test "map" do
    assert Render.to_string(%{one: 1, two: 2}) == ~s/{"two":2,"one":1}/
  end

  test "Decimal" do
    assert Render.to_string(Decimal.new(10.99)) == "10.99"
  end

  test "Ecto.Date" do
    date_str = "2016-12-10"
    date = Ecto.Date.cast!(date_str)
    assert Render.to_string(date) == date_str
  end

  test "Ecto.Time" do
    time_str = "23:01:01"
    time = Ecto.Time.cast!(time_str)
    assert Render.to_string(time) == time_str
  end

  test "Ecto.DateTime" do
    dt_str = "2016-12-13 10:10:10"
    dt = Ecto.DateTime.cast!(dt_str)
    result = Render.to_string(dt)
    assert String.starts_with?(result, "2016-12-13 ")
    assert String.ends_with?(result, ":10:10")
  end

  test "Ecto.DateTime without localtime conversion" do
    Application.put_env(:ex_admin, :convert_local_time, false)
    dt_str = "2016-12-13 10:10:10"
    dt = Ecto.DateTime.cast!(dt_str)
    assert Render.to_string(dt) == "2016-12-13 10:10:10"
    Application.put_env(:ex_admin, :convert_local_time, true)
  end

  test "Date" do
    assert Render.to_string(~D[2016-10-10]) == "2016-10-10"
  end

  test "Time" do
    assert Render.to_string(~T[15:30:00]) == "15:30:00"
  end

  test "DateTime" do
    dt = DateTime.from_unix!(1_464_096_368)
    result = Render.to_string(dt)
    assert String.starts_with?(result, "2016-05-24 ")
    assert String.ends_with?(result, ":26:08")
  end
end
