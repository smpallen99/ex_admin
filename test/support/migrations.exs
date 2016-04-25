defmodule TestExAdmin.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      timestamps
    end

    create table(:products) do
      add :title, :string
      add :price, :decimal
      add :product_id, references(:products, on_delete: :nothing)
      timestamps
    end

    create table(:noids, primary_key: false) do
      add :name, :string, primary_key: true
      add :description, :text
      timestamps
    end

    create table(:noprimarys, primary_key: false) do
      add :index, :integer
      add :name, :string
      add :description, :string 
      timestamps
    end
  end
end

