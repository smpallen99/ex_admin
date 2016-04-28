defmodule TestExAdmin.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
    end

    create table(:products) do
      add :title, :string
      add :price, :decimal
      add :product_id, references(:products, on_delete: :nothing)
    end

    create table(:noids, primary_key: false) do
      add :name, :string, primary_key: true
      add :description, :text
      add :company, :string
      add :user_id, references(:users, on_delete: :nothing)
    end
    create index(:noids, [:user_id])

    create table(:noprimarys, primary_key: false) do
      add :index, :integer
      add :name, :string
      add :description, :string
    end
  end
end

