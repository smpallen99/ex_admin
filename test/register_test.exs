defmodule TestExAdmin.ExAdmin.Test do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    controller do
      before_filter(:one, only: [:create, :update])
      after_filter(:two)

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
      before_filter(:one, only: [:create, :update])
      before_filter(:two, only: [:update])

      after_filter(:three)

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

defmodule TestExAdmin.ActionItemWithClear do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    clear_action_items!()
    action_item(:index, fn -> :test end)
  end
end

defmodule TestExAdmin.ActionItem do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    action_item(:index, fn -> :test end)
  end
end

defmodule TestExAdmin.DefaultActions do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
  end
end

defmodule TestExAdmin.MemberCollectionAction do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    member_action(:my_member, &__MODULE__.my_member/2)
  end

  def my_member(conn, _simple) do
    conn
  end
end

###############

defmodule TestExAdmin.RegisterTest do
  use ExUnit.Case, async: true
  alias ExAdmin.Register

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

  test "default action items" do
    result = %TestExAdmin.DefaultActions{}.actions

    unless Enum.count(result) == 4 do
      refute result
    end

    assert Enum.all?(result, &(&1 in [:edit, :show, :new, :delete]))
  end

  test "action item with clear" do
    result = %TestExAdmin.ActionItemWithClear{}.actions
    assert Enum.count(result) == 1
    assert {:fn, _, _} = result[:index]
  end

  test "action item" do
    result = %TestExAdmin.ActionItem{}.actions
    assert Enum.count(result) == 5
    assert {:fn, _, _} = result[:index]
  end

  @all_options [:edit, :show, :new, :delete]

  test "action_items" do
    all = @all_options
    assert Register.get_action_items(all, @all_options) == all
    only = [[only: [:show, :edit]] | all]
    assert Register.get_action_items(only, @all_options) == [:show, :edit]

    except = [[except: [:edit, :new, :delete]] | all]
    assert Register.get_action_items(except, @all_options) == [:show]
  end

  test "action_items with action_item" do
    show = {
      :show,
      {:fn, [line: 78],
       [
         {:->, [line: 78],
          [
            [{:id, [line: 78], nil}],
            {:action_item_link, [line: 79],
             [
               "Lock User!",
               [
                 href:
                   {:<<>>, [line: 79],
                    [
                      "/admin/users/lock/",
                      {:::, [line: 79],
                       [
                         {{:., [line: 79], [Kernel, :to_string]}, [line: 79],
                          [
                            {:id, [line: 79], nil}
                          ]},
                         {:binary, [line: 79], nil}
                       ]}
                    ]},
                 "data-method": :put
               ]
             ]}
          ]}
       ]}
    }

    index = {:index, quote(do: fn -> :test end)}

    all = [show | @all_options]
    assert Register.get_action_items(all, @all_options) == all
    only = [[only: [:show, :edit]] | all]
    assert Register.get_action_items(only, @all_options) == [show | [:show, :edit]]

    all = [index, show | @all_options]
    assert Register.get_action_items(all, @all_options) == all

    except = [[except: [:show, :edit]] | all]
    assert Register.get_action_items(except, @all_options) == [index, show | [:new, :delete]]
  end
end
