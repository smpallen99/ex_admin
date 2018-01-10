defmodule ExAdmin.ThemeFilterTest do
  use ExUnit.Case
  alias ExAdmin.Theme.{ActiveAdmin, AdminLte2}

  def all(TestExAdmin.User = model) do
    [struct(model.__struct__, id: 1, name: "test")]
  end

  def all(TestExAdmin.UUIDSchema = model) do
    [struct(model.__struct__, key: Ecto.UUID.generate(), name: "test")]
  end

  def all(_), do: []

  setup do
    save = Application.get_env(:ex_admin, :repo)
    Application.put_env(:ex_admin, :repo, __MODULE__)

    on_exit(fn ->
      Application.put_env(:ex_admin, :repo, save)
    end)

    :ok
  end

  #################
  # AdminLte2

  test "AdminLte2 build_field string" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    html = AdminLte2.Filter.build_field({:name, :string}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Search Name"
  end

  test "AdminLte2 build_field string with label option" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [email: [label: "EMail Address"]]}
    html = AdminLte2.Filter.build_field({:email, :string}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Search EMail Address"
  end

  test "AdminLte2 build_field datetime" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: []}
    html = AdminLte2.Filter.build_field({:inserted_at, Ecto.DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Inserted At"
  end

  test "AdminLte2 build_field native datetime" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: []}
    html = AdminLte2.Filter.build_field({:inserted_at, DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Inserted At"
  end

  test "AdminLte2 build_field datetime with label option" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: [inserted_at: [label: "Created On"]]}
    html = AdminLte2.Filter.build_field({:inserted_at, Ecto.DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Created On"
  end

  test "AdminLte2 build_field integer" do
    defn = %TestExAdmin.ExAdmin.Noprimary{index_filters: []}
    html = AdminLte2.Filter.build_field({:index, :integer}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Index"
  end

  test "AdminLte2 build_field integer with label option" do
    defn = %TestExAdmin.ExAdmin.Noprimary{index_filters: [index: [label: "Index Number"]]}
    html = AdminLte2.Filter.build_field({:index, :integer}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Index Number"
  end

  test "AdminLte2 build_field belongs_to" do
    # save = Application.get_env :ex_admin, :repo
    # Application.put_env :ex_admin, :repo, __MODULE__
    defn = %TestExAdmin.ExAdmin.Product{index_filters: []}
    assoc = defn.resource_model.__schema__(:association, :user)
    html = AdminLte2.Filter.build_field({:user, assoc}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "User"
    # Application.put_env :ex_admin, :repo, save
  end

  test "AdminLte2 build_field belongs_to with label option" do
    # save = Application.get_env :ex_admin, :repo
    # Application.put_env :ex_admin, :repo, __MODULE__
    defn = %TestExAdmin.ExAdmin.Product{index_filters: [user: [label: "Account"]]}
    assoc = defn.resource_model.__schema__(:association, :user)
    html = AdminLte2.Filter.build_field({:user, assoc}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Account"
    # Application.put_env :ex_admin, :repo, save
  end

  test "AdminLte2 build_field boolean" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    html = AdminLte2.Filter.build_field({:active, :boolean}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Active"
  end

  test "AdminLte2 build_field boolean with label option" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [active: [label: "active?"]]}
    html = AdminLte2.Filter.build_field({:active, :boolean}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "active?"
  end

  test "AdminLte2 build_field UUID" do
    defn = %TestExAdmin.ExAdmin.UUIDSchema{index_filters: []}
    html = AdminLte2.Filter.build_field({:key, Ecto.UUID}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Key"
  end

  test "AdminLte2 build_field UUID with label option" do
    defn = %TestExAdmin.ExAdmin.UUIDSchema{index_filters: [key: [label: "id"]]}
    html = AdminLte2.Filter.build_field({:key, Ecto.UUID}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "id"
  end

  #################
  # ActiveAdmin

  test "ActiveAdmin build_field string" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:name, :string}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Name"
  end

  test "ActiveAdmin build_field string with label option" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [email: [label: "EMail Address"]]}
    html = ActiveAdmin.Filter.build_field({:email, :string}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "EMail Address"
  end

  test "ActiveAdmin build_field datetime" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:inserted_at, Ecto.DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Inserted At"
  end

  test "ActiveAdmin build_field native datetime" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:inserted_at, DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Inserted At"
  end

  test "ActiveAdmin build_field datetime with label option" do
    defn = %TestExAdmin.ExAdmin.Simple{index_filters: [inserted_at: [label: "Created On"]]}
    html = ActiveAdmin.Filter.build_field({:inserted_at, Ecto.DateTime}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Created On"
  end

  test "ActiveAdmin build_field integer" do
    defn = %TestExAdmin.ExAdmin.Noprimary{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:index, :integer}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Index"
  end

  test "ActiveAdmin build_field integer with label option" do
    defn = %TestExAdmin.ExAdmin.Noprimary{index_filters: [index: [label: "Index Number"]]}
    html = ActiveAdmin.Filter.build_field({:index, :integer}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Index Number"
  end

  test "ActiveAdmin build_field belongs_to" do
    defn = %TestExAdmin.ExAdmin.Product{index_filters: []}
    assoc = defn.resource_model.__schema__(:association, :user)
    html = ActiveAdmin.Filter.build_field({:user, assoc}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "User"
  end

  test "ActiveAdmin build_field belongs_to with label option" do
    defn = %TestExAdmin.ExAdmin.Product{index_filters: [user: [label: "Account"]]}
    assoc = defn.resource_model.__schema__(:association, :user)
    html = ActiveAdmin.Filter.build_field({:user, assoc}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Account"
  end

  test "ActiveAdmin build_field boolean" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:active, :boolean}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Active"
  end

  test "ActiveAdmin build_field boolean with label option" do
    defn = %TestExAdmin.ExAdmin.User{index_filters: [active: [label: "active?"]]}
    html = ActiveAdmin.Filter.build_field({:active, :boolean}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "active?"
  end

  test "ActiveAdmin build_field UUID" do
    defn = %TestExAdmin.ExAdmin.UUIDSchema{index_filters: []}
    html = ActiveAdmin.Filter.build_field({:key, Ecto.UUID}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "Key"
  end

  test "ActiveAdmin build_field UUID with label option" do
    defn = %TestExAdmin.ExAdmin.UUIDSchema{index_filters: [key: [label: "id"]]}
    html = ActiveAdmin.Filter.build_field({:key, Ecto.UUID}, nil, defn)
    assert Floki.find(html, "label.label") |> Floki.text() == "id"
  end
end
