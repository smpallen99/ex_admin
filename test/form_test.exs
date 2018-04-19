defmodule ExAdmin.FormTest do
  use ExUnit.Case, async: true
  alias TestExAdmin.{Simple, User, Role, Repo}
  use Xain

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)

    conn =
      Plug.Conn.assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
      |> struct(params: %{})

    {:ok, conn: conn}
  end

  test "build_control string" do
    res = ExAdmin.Form.build_control(:string, %Simple{}, %{}, "simple", :name, "simple_name")
    assert res =~ "<input"
    assert res =~ "id='simple_name'"
    assert res =~ "type='text'"
    assert res =~ "name='simple[name]'"
  end

  test "build_control DateTime" do
    res =
      ExAdmin.Form.build_control(
        Ecto.DateTime,
        %Simple{inserted_at: Ecto.DateTime.utc()},
        %{},
        "simple",
        :inserted_at,
        "simple_inserted_at"
      )

    select = Floki.find(res, "select[name='simple[inserted_at][year]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][year]'] option")
    refute options == []

    select = Floki.find(res, "select[name='simple[inserted_at][hour]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][hour]'] option")
    refute options == []
  end

  test "build_control NativeDateTime" do
    res =
      ExAdmin.Form.build_control(
        DateTime,
        %Simple{inserted_at: DateTime.utc_now()},
        %{},
        "simple",
        :inserted_at,
        "simple_inserted_at"
      )

    select = Floki.find(res, "select[name='simple[inserted_at][year]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][year]'] option")
    refute options == []

    select = Floki.find(res, "select[name='simple[inserted_at][hour]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][hour]'] option")
    refute options == []
  end

  test "build_control Date" do
    res =
      ExAdmin.Form.build_control(
        Ecto.Date,
        %Simple{inserted_at: Ecto.DateTime.utc()},
        %{},
        "simple",
        :inserted_at,
        "simple_inserted_at"
      )

    select = Floki.find(res, "select[name='simple[inserted_at][year]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][month]'] option")
    refute options == []
  end

  test "build_control Date with prompts" do
    res =
      ExAdmin.Form.build_control(
        Ecto.Date,
        %Simple{inserted_at: Ecto.DateTime.utc()},
        %{options: [year: [prompt: "year"], month: [prompt: "month"], day: [prompt: "day"]]},
        "simple",
        :inserted_at,
        "simple_inserted_at"
      )

    year_prompt =
      res
      |> Floki.find("select[name='simple[inserted_at][year]'] option[value='']")

    assert year_prompt == [{"option", [{"value", ""}], ["year"]}]

    month_prompt =
      res
      |> Floki.find("select[name='simple[inserted_at][month]'] option[value='']")

    assert month_prompt == [{"option", [{"value", ""}], ["month"]}]

    day_prompt =
      res
      |> Floki.find("select[name='simple[inserted_at][day]'] option[value='']")

    assert day_prompt == [{"option", [{"value", ""}], ["day"]}]
  end

  test "build_control Time" do
    res =
      ExAdmin.Form.build_control(
        Ecto.Time,
        %Simple{inserted_at: Ecto.DateTime.utc()},
        %{},
        "simple",
        :inserted_at,
        "simple_inserted_at"
      )

    select = Floki.find(res, "select[name='simple[inserted_at][hour]']")
    refute select == []
    options = Floki.find(res, "select[name='simple[inserted_at][min]'] option")
    refute options == []
  end

  test "build_control :boolean" do
    res = ExAdmin.Form.build_control(:boolean, %User{}, %{}, "user", :active, "user_active")
    checkbox = Floki.find(res, "input#user_active[type=checkbox]")
    assert Floki.attribute(checkbox, "name") == ["user[active]"]
  end

  test "build_item :input", %{conn: conn} do
    resource = %Simple{}
    item = %{type: :input, name: :name, opts: %{}, resource: resource}
    res = ExAdmin.Form.build_item(conn, item, resource, "simple", nil)

    label = Floki.find(res, "label")
    assert Floki.text(label) == "Name"

    input = Floki.find(res, "input#simple_name")
    assert Floki.attribute(input, "type") == ["text"]
    assert Floki.attribute(input, "name") == ["simple[name]"]
  end

  test "build_item :inputs as: :check_boxes collection", %{conn: conn} do
    roles =
      for name <- ~w(user admin) do
        Repo.insert!(Role.changeset(%Role{}, %{name: name}))
      end

    item = %{type: :inputs, name: :roles, opts: %{as: :check_boxes, collection: roles}}
    res = ExAdmin.Form.build_item(conn, item, %User{}, "user", nil)
    assert Floki.find(res, "div label") |> hd |> Floki.text() == "Roles"
    role_boxes = Floki.find(res, "div div.col-sm-10 input[type=checkbox]")
    assert Enum.count(role_boxes) == 2
  end

  test "build_item :inputs as: :check_boxes collection default collection", %{conn: conn} do
    for name <- ~w(user admin) do
      Repo.insert!(Role.changeset(%Role{}, %{name: name}))
    end

    item = %{type: :inputs, name: :roles, opts: %{as: :check_boxes}}
    res = ExAdmin.Form.build_item(conn, item, %User{}, "user", nil)
    assert Floki.find(res, "div label") |> hd |> Floki.text() == "Roles"
    role_boxes = Floki.find(res, "div div.col-sm-10 input[type=checkbox]")
    assert Enum.count(role_boxes) == 2
  end

  test "build_item :inputs  collection", %{conn: conn} do
    roles =
      for name <- ~w(user admin) do
        Repo.insert!(Role.changeset(%Role{}, %{name: name}))
      end

    item = %{type: :inputs, name: :roles, opts: %{collection: roles}}
    res = ExAdmin.Form.build_item(conn, item, %User{}, "user", nil)
    assert Floki.find(res, "div label") |> hd |> Floki.text() == "Roles"
    options = Floki.find(res, "select[multiple=multiple] option")
    assert Enum.count(options) == 2
  end

  # test "build_item :has_many", %{conn: conn} do
  #   fun = fn(_p) ->
  #     [%{name: :number, opts: %{},
  #        resource: {TestExAdmin.PhoneNumber, TestExAdmin.ContactPhoneNumber},
  #        type: :input},
  #      %{name: :label,
  #        opts: %{collection: ["Primary Phone", "Secondary Phone", "Home Phone",
  #           "Work Phone", "Mobile Phone", "Other Phone"]},
  #        resource: {TestExAdmin.PhoneNumber, TestExAdmin.ContactPhoneNumber},
  #        type: :input}]
  #   end
  #   resource = Repo.insert! Contact.changeset(%Contact{}, %{first_name: "First", last_name: "Last"})
  #   numbers = for {label, number} <- [{"Home", "5555555555"}, {"Work", "5555555551"}] do
  #     pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{number: number, label: label})
  #     Repo.insert! ContactPhoneNumber.changeset(%ContactPhoneNumber{}, %{contact_id: resource.id, phone_number_id: pn.id})
  #   end
  #   item = %{type: :has_many, resource: nil, name: :phone_numbers, opts: %{fun: fun}}
  #   res = ExAdmin.Form.build_item(conn, item, resource, "contact", nil)
  #   assert res == ""
  # end
end
