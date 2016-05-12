defmodule TestExAdmin.Migrations do
  use Ecto.Migration

  def change do

    create table(:posts) do
      add :title, :string, size: 100
      add :text, :binary
    end

    create table(:comments) do
      add :text, :string
      add :post_id, references(:posts, on_delete: :delete_all)
    end

    create table(:users) do
      add :name, :string
      add :email, :string
    end

    create table(:roles) do
      add :name, :string
    end

    create table(:users_roles) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :role_id, references(:roles, on_delete: :delete_all)
      timestamps
    end

    create index(:users_roles, [:user_id])
    create index(:users_roles, [:role_id])

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

