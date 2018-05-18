defmodule ExAdmin.ThemeFormTest do
  use ExUnit.Case
  alias ExAdmin.Theme.{ActiveAdmin, AdminLte2}
  alias TestExAdmin.{Repo, PhoneNumber}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestExAdmin.Repo)
    conn = Plug.Conn.assign(%Plug.Conn{}, :theme, ExAdmin.Theme.AdminLte2)
    |> struct(params: %{})
    {:ok, conn: conn}
  end

  test "AdminLte2 theme_build_has_many_fieldset", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555"})
    fields = build_fields pn

    {inx, html} = AdminLte2.Form.theme_build_has_many_fieldset(conn, pn, fields, 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)

    assert inx == 0

    assert Floki.find(html, "div div h3") |> Floki.text == "Phone Number"

  end

  test "AdminLte2 theme_build_has_many_fieldset with labels", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555"})
    fields = build_fields(pn, %{label: "Telephone Number"})

    {inx, html} = AdminLte2.Form.theme_build_has_many_fieldset(conn, pn, fields, 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)

    assert inx == 0

    assert Floki.find(html, "div div label") |> Floki.text == "Telephone Number*Label*Remove"
  end
  
  test "AdminLte2 theme_build_has_many_fieldset with labels and types", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555", contacted_on: Ecto.Date.utc})
    fields = build_fields(pn, %{label: "Telephone Number"})
    contacted_on = %{name: :contacted_on, opts: %{type: :date}, resource: pn, type: :input}

    {inx, html} = AdminLte2.Form.theme_build_has_many_fieldset(conn, pn, [contacted_on | fields], 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)

    assert inx == 0

    assert Floki.find(html, "div div input") |> Floki.attribute("type") == ["text", "date", "hidden", "checkbox"]
  end

  test "AdminLte2 theme_build_has_many_fieldset with errors", %{conn: conn} do
    pn =  %{_destroy: "0", label: "Primary Phone", number: nil}
    fields = [%{name: :label,
     opts: %{collection: ["Primary Phone", "Secondary Phone", "Home Phone",
        "Work Phone", "Mobile Phone", "Other Phone"]},
     resource: {:"1483112783869",
      %{_destroy: "0", label: "Primary Phone", number: nil}}, type: :input},
      %{name: :number, opts: %{},
        resource: {:"1483112783869",
        %{_destroy: "0", label: "Primary Phone", number: nil}}, type: :input}]


    {inx, html} = AdminLte2.Form.theme_build_has_many_fieldset(conn, pn, fields, 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", [])

    assert inx == 0

    assert Floki.find(html, "div div h3") |> Floki.text == "Phone Number"

  end


  test "ActiveAdmin theme_build_has_many_fieldset", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555"})
    fields = build_fields pn

    {inx, html} = ActiveAdmin.Form.theme_build_has_many_fieldset(conn, pn, fields, 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)

    assert inx == 0

    assert Floki.find(html, "fieldset ol h3") |> Floki.text == "Phone Number"
  end
  
  test "ActiveAdmin theme_build_has_many_fieldset with labels", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555"})
    fields = build_fields(pn, %{label: "Telephone Number"})

    {inx, html} = ActiveAdmin.Form.theme_build_has_many_fieldset(conn, pn, fields, 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)

    assert inx == 0


    assert Floki.find(html, "label") |> Floki.text == "RemoveLabel*Telephone Number*"
  end

  test "ActiveAdmin theme_build_has_many_fieldset with labels and types", %{conn: conn} do
    pn = Repo.insert! PhoneNumber.changeset(%PhoneNumber{}, %{label: "Home Phone", number: "5555555555", contacted_on: Ecto.Date.utc})
    fields = build_fields(pn, %{label: "Telephone Number"})
    contacted_on = %{name: :contacted_on, opts: %{type: :date}, resource: pn, type: :input}

    {inx, html} = ActiveAdmin.Form.theme_build_has_many_fieldset(conn, pn, [contacted_on | fields], 0, "contact_phone_numbers_attributes_0",
      :phone_numbers, "phone_numbers_attributes", "contact", nil)


    assert inx == 0

    assert Floki.find(html, "input") |> Floki.attribute("type") == ["hidden", "checkbox", "date", "text"]
  end

  ################
  # Helpers

  defp build_fields(resource, opts \\ %{}) do
    [
      %{
        name: :label, resource: resource, type: :input,
        opts: %{collection: PhoneNumber.labels},
      },
      %{name: :number, opts: opts, resource: resource, type: :input}
    ]
  end
end
