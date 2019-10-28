defmodule ExAdminTest.TableTest do
  use ExUnit.Case, async: true
  alias ExAdmin.Table

  def index_actions(_, _, _), do: nil

  setup do
    table_options = %{
      fields: [:id, :name, :inserted_at],
      filter: "",
      order: nil,
      page: %{page_number: 1},
      path_prefix: "/admin/users?order=",
      scope: nil,
      selectable: true,
      selectable_column: true,
      sort: "desc"
    }

    {:ok, %{table_opts: table_options}}
  end

  describe "build_th" do
    test "actions", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-actions'>Actions</th>"}
      opts = {"Actions", %{fun: &index_actions/3}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "link field", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable th-id'><a href='/admin/users?order=id_desc&amp;page=1'>Id</a></th>"}

      opts = {:id, %{link: true}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "date field", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable th-inserted_at'><a href='/admin/users?order=inserted_at_desc&amp;page=1'>Inserted At</a></th>"}

      opts = {:inserted_at, %{}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "sortable with scope", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable th-id'><a href='/admin/users?order=id_desc&amp;page=1&amp;scope=complete'>Id</a></th>"}

      table_options = put_in(table_options, [:scope], "complete")
      opts = {:id, %{}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "filtered", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable sorted-desc th-id'><a href='/admin/users?order=id_asc&amp;page=1&amp;q%5Btotal_price_gt%5D=100'>Id</a></th>"}

      table_options = %{
        table_options
        | filter: "&q%5Btotal_price_gt%5D=100",
          order: {"id", "desc"}
      }

      opts = {:id, %{}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "order asc", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable sorted-asc th-id'><a href='/admin/users?order=id_desc&amp;page=1'>Id</a></th>"}

      table_options = %{table_options | order: {"id", "asc"}}
      opts = {:id, %{}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "atom field_name binary label", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-id'>Record Id</th>"}
      opts = {:id, %{label: "Record Id"}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "binary field_name binary label", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-record'>Record Id</th>"}
      opts = {"record", %{label: "Record Id"}}
      assert Table.build_th(opts, table_options) == expected
    end

    test "field name and table opts - no tuple", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-id'>Id</th>"}
      assert Table.build_th(:id, table_options) == expected
      assert Table.build_th("id", table_options) == expected
    end

    test "field name, opts and table opts - no tuple", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-id'>Record Id</th>"}
      opts = %{label: "Record Id"}
      assert Table.build_th("id", opts, table_options) == expected
    end

    test "field name, fields in table_options - no tuple", %{table_opts: table_options} do
      expected =
        {:safe,
         "<th class='sortable th-id'><a href='/admin/users?order=id_desc&amp;page=1'>Id</a></th>"}

      table_options = put_in(table_options, [:fields], [:id])
      assert Table.build_th("id", %{link: true}, table_options) == expected
      assert Table.build_th("id", %{}, table_options) == expected
    end

    test "field name, no field in table_options - no tuple", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-id'>Id</th>"}
      table_options = put_in(table_options, [:fields], [:name])
      assert Table.build_th("id", %{link: true}, table_options) == expected
      assert Table.build_th("id", %{}, table_options) == expected
    end

    test "parameterize binary field", %{table_opts: table_options} do
      expected = {:safe, "<th class='th-some_field'>Some Field</th>"}
      assert Table.build_th("some field", %{}, table_options) == expected
    end
  end
end
