defmodule TestExAdmin.ExAdmin.SimpleCustom do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    action_item(:index, fn -> action_item_link("Custom Action", href: "/custom") end)
    action_item(:show, fn id -> action_item_link("Custom Show", href: "/custom/#{id}") end)
  end
end

defmodule ExAdminTest do
  use ExUnit.Case, async: true

  setup config do
    if defn = config[:as_resource] do
      resource = struct(defn.resource_model.__struct__, id: 1)

      conn =
        Plug.Conn.assign(%Plug.Conn{}, :defn, defn)
        |> Plug.Conn.assign(:resource, resource)
        |> struct(params: %{"id" => "1"})
        |> struct(private: %{phoenix_action: :show})

      {:ok, defn: defn, conn: conn}
    else
      :ok
    end
  end

  @tag as_resource: %TestExAdmin.ExAdmin.Simple{}
  test "action_button", %{defn: defn, conn: conn} do
    result = ExAdmin.action_button(conn, defn, "Simple", :show, :edit, defn.actions, "17")
    assert result == [{"Edit Simple", [href: "/admin/simples/1/edit"]}]

    result = ExAdmin.action_button(conn, defn, "Simple", :show, :new, defn.actions, "17")
    assert result == [{"New Simple", [href: "/admin/simples/new"]}]

    result = ExAdmin.action_button(conn, defn, "Simple", :show, :delete, defn.actions, "17")

    assert result == [
             {"Delete Simple",
              [
                href: "/admin/simples/1",
                "data-confirm": "Are you sure you want to delete this?",
                "data-method": :delete,
                rel: :nofollow
              ]}
           ]

    result = ExAdmin.action_button(conn, defn, "Simple", :index, :new, defn.actions, "17")
    assert result == [{"New Simple", [href: "/admin/simples/new"]}]

    result = ExAdmin.action_button(conn, defn, "Simple", :edit, :new, defn.actions, "17")
    assert result == [{"New Simple", [href: "/admin/simples/new"]}]
  end

  @tag as_resource: %TestExAdmin.ExAdmin.Simple{}
  test "default_resource_title_actions", %{defn: defn, conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :show})
    result = ExAdmin.default_resource_title_actions(conn, defn)

    assert result == [
             edit: [{"Edit Simple", [href: "/admin/simples/1/edit"]}],
             new: [{"New Simple", [href: "/admin/simples/new"]}],
             delete: [
               {"Delete Simple",
                [
                  href: "/admin/simples/1",
                  "data-confirm": "Are you sure you want to delete this?",
                  "data-method": :delete,
                  rel: :nofollow
                ]}
             ]
           ]

    conn = struct(conn, private: %{phoenix_action: :index})
    result = ExAdmin.default_resource_title_actions(conn, defn)

    assert result == [new: [{"New Simple", [href: "/admin/simples/new"]}]]
    conn = struct(conn, private: %{phoenix_action: :edit})

    result = ExAdmin.default_resource_title_actions(conn, defn)
    assert result == [new: [{"New Simple", [href: "/admin/simples/new"]}]]
  end

  @tag as_resource: %TestExAdmin.ExAdmin.SimpleCustom{}
  test "default_resource_title_actions custom actions", %{defn: defn, conn: conn} do
    conn = struct(conn, private: %{phoenix_action: :index})
    result = ExAdmin.default_resource_title_actions(conn, defn)

    assert result == [
             new: [{"New Simple", [href: "/admin/simples/new"]}],
             custom: [{"Custom Action", [href: "/custom"]}]
           ]

    conn = struct(conn, private: %{phoenix_action: :show})
    result = ExAdmin.default_resource_title_actions(conn, defn)

    assert result == [
             edit: [{"Edit Simple", [href: "/admin/simples/1/edit"]}],
             new: [{"New Simple", [href: "/admin/simples/new"]}],
             delete: [
               {"Delete Simple",
                [
                  href: "/admin/simples/1",
                  "data-confirm": "Are you sure you want to delete this?",
                  "data-method": :delete,
                  rel: :nofollow
                ]}
             ],
             custom: [{"Custom Show", [href: "/custom/1"]}]
           ]
  end
end
