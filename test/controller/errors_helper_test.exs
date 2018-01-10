defmodule TestExAdmin.ErrorsHelperTests do
  use ExUnit.Case

  defmodule TestExAdmin.Contact do
    import Ecto.Changeset
    use Ecto.Schema

    schema "contacts" do
      field(:first_name, :string, null: false)
      field(:birthday, :date)

      many_to_many(
        :phone_numbers,
        TestExAdmin.PhoneNumber,
        join_through: TestExAdmin.ContactPhoneNumber
      )

      timestamps()
    end

    @fields ~w(first_name)a

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, [:birthday | @fields])
      |> validate_required(@fields)
      |> cast_assoc(:phone_numbers, required: false)
    end
  end

  defmodule TestExAdmin.ContactPhoneNumber do
    import Ecto.Changeset
    use Ecto.Schema

    schema "contacts_phone_numbers" do
      belongs_to(:contact, TestExAdmin.Contact)
      belongs_to(:phone_number, TestExAdmin.PhoneNumber)

      timestamps()
    end

    @fields ~w(contact_id phone_number_id)a

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, @fields)
      |> validate_required(@fields)
      |> assoc_constraint(:contact)
      |> assoc_constraint(:phone_number)
    end
  end

  defmodule TestExAdmin.PhoneNumber do
    import Ecto.Changeset
    use Ecto.Schema

    schema "phone_numbers" do
      field(:number, :string, null: false)
      field(:label, :string, null: false)

      has_many(:contacts_phone_numbers, TestExAdmin.ContactPhoneNumber)
      has_many(:contacts, through: [:contacts_phone_numbers, :contact])

      timestamps()
    end

    @fields ~w(number label)a

    def changeset(model, params \\ %{}) do
      model
      |> cast(params, @fields)
      |> validate_required([:number, :label])
      |> validate_length(:number, min: 1, max: 255)
      |> validate_length(:label, min: 1, max: 255)
    end
  end

  test "simple errors" do
    params = %{}
    changeset = TestExAdmin.Contact.changeset(%TestExAdmin.Contact{}, params)

    errors = ExAdmin.ErrorsHelper.create_errors(changeset, TestExAdmin.Contact)
    assert changeset.valid? == false
    assert errors == [first_name: {"can't be blank", [validation: :required]}]
  end

  test "simple errors when schema has field with struct type" do
    params = %{birthday: %{day: 8, month: 6, year: 2017}}
    changeset = TestExAdmin.Contact.changeset(%TestExAdmin.Contact{}, params)

    errors = ExAdmin.ErrorsHelper.create_errors(changeset, TestExAdmin.Contact)
    assert changeset.valid? == false
    assert errors == [first_name: {"can't be blank", [validation: :required]}]
  end

  test "nested errors are squashed" do
    params = %{
      phone_numbers: %{"1483927542828": %{_destroy: "0", label: "Primary Phone", number: nil}}
    }

    changeset = TestExAdmin.Contact.changeset(%TestExAdmin.Contact{}, params)

    errors = ExAdmin.ErrorsHelper.create_errors(changeset, TestExAdmin.Contact)
    assert changeset.valid? == false

    assert errors == [
             first_name: {"can't be blank", [validation: :required]},
             phone_numbers_attributes_0_number: {"can't be blank", [validation: :required]}
           ]
  end
end
