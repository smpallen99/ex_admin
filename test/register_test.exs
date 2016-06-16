defmodule TestExAdmin.ExAdmin.Test do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    controller do
      before_filter :one, only: [:create, :update]
      after_filter :two

      def one(conn, params) do
        {conn, Map.put(params, before: 1)}
      end
      def two(conn, params) do
        {conn, Map.put(params, after: 2)}
      end
    end
  end
end
defmodule TestExAdmin.ExAdmin.Test2 do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    controller do
      before_filter :one, only: [:create, :update]
      before_filter :two, only: [:update]

      after_filter :three

      def one(conn, params) do
        {conn, Map.put(params, one: 1)}
      end
      def two(conn, params) do
        {conn, Map.put(params, two: 2)}
      end
      def three(conn, params) do
        {conn, Map.put(params, three: 2)}
      end
    end
  end
end

defmodule ExAdminTest.RegisterTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, defn: %TestExAdmin.ExAdmin.Test{}, defn2: %TestExAdmin.ExAdmin.Test2{}}
  end

  test "before_filter", %{defn: defn} do
    assert defn.controller_filters[:before_filter] == [one: [only: [:create, :update]]]
  end
  test "after_filter", %{defn: defn} do
    assert defn.controller_filters[:after_filter] == [two: []]
  end

  test "multiple before filters", %{defn2: defn} do
    expected = [one: [only: [:create, :update]], two: [only: [:update]]]
    assert defn.controller_filters[:before_filter] == expected

  end
end
