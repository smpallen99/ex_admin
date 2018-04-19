defmodule TestExAdmin.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:email, :string)
      add(:active, :boolean)
    end

    create table(:roles) do
      add(:name, :string)
    end

    create table(:users_roles) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:role_id, references(:roles, on_delete: :delete_all))
      timestamps()
    end

    create(index(:users_roles, [:user_id]))
    create(index(:users_roles, [:role_id]))

    create table(:products) do
      add(:title, :string)
      add(:price, :decimal)
      add(:user_id, references(:users, on_delete: :delete_all))
    end

    create table(:noids, primary_key: false) do
      add(:name, :string, primary_key: true)
      add(:description, :text)
      add(:company, :string)
      add(:user_id, references(:users, on_delete: :nothing))
    end

    create(index(:noids, [:user_id]))

    create table(:noprimarys, primary_key: false) do
      add(:index, :integer)
      add(:name, :string)
      add(:description, :string)
      timestamps()
    end

    create table(:simples) do
      add(:name, :string)
      add(:description, :string)
      timestamps()
    end

    create table(:custom_changeset) do
      add(:name, :string)
      add(:description, :string)
      timestamps()
    end

    create table(:restricteds) do
      add(:name, :string)
      add(:description, :string)
    end

    create table(:contacts) do
      add(:first_name, :string)
      add(:last_name, :string)
      timestamps()
    end

    create table(:phone_numbers) do
      add(:number, :string)
      add(:label, :string)
      timestamps()
    end

    create table(:contacts_phone_numbers) do
      add(:contact_id, references(:contacts, on_delete: :delete_all))
      add(:phone_number_id, references(:phone_numbers, on_delete: :delete_all))
    end

    create(index(:contacts_phone_numbers, [:contact_id]))
    create(index(:contacts_phone_numbers, [:phone_number_id]))

    create table(:uuid_schemas, primary_key: false) do
      add(:key, :uuid, primary_key: true)
      add(:name, :string)
    end
  end
end
