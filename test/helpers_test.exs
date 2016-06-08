defmodule ExAdmin.HelpersTest do
  use ExUnit.Case
  alias ExAdmin.Helpers
  alias TestExAdmin.Noid
  alias TestExAdmin.Simple
  use Xain

  test "build_field" do
    res = Helpers.build_field(%Noid{description: "desc"}, %{},
      {:description, %{}}, fn(contents, field_name) ->
        ExAdmin.Table.handle_contents(contents, field_name)
      end)
    assert res == ~s(<td class='td-description'>desc</td>)
  end

  test "build_field Actions" do
    resource = %Simple{name: "N", description: "D", id: 1}
    conn = Plug.Conn.assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
    expected = "<td class='td-actions'><a href='/admin/simples/1' class='member_link view_link'>View</a>" <>
      "<a href='/admin/simples/1/edit' class='member_link edit_link'>Edit</a>" <>
      "<a href='/admin/simples/1' class='member_link delete_link'" <>
      " data-confirm='Are you sure you want to delete this?'" <>
      " data-remote='true' data-method='delete' rel='nofollow'>Delete</a></td>"

    res = Helpers.build_field(resource, conn, {"Actions", %{fun: fn(res) ->
      ExAdmin.Index.build_index_links(conn, res, []) end}},
      fn(contents, field_name) ->
        ExAdmin.Table.handle_contents(contents, field_name)
      end)
    assert res == expected
  end
end
