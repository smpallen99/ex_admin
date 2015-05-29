
```Elixir
C.__schema__(:associations)
[:category, :contacts_phone_numbers, :phone_numbers, :contacts_groups, :groups]
```

```Elixir
C.__schema__(:association, :contacts_phone_numbers)
%Ecto.Associations.Has{assoc: UcxCallout.ContactPhoneNumber,
 assoc_key: :contact_id, cardinality: :many, field: :contacts_phone_numbers,
 owner: UcxCallout.Contact, owner_key: :id}
```

```Elixir
C.__schema__(:association, :phone_numbers)
%Ecto.Associations.HasThrough{cardinality: :many, field: :phone_numbers,
 owner: UcxCallout.Contact, owner_key: :id,
 through: [:contacts_phone_numbers, :phone_number]}
```

```Elixir
Pn.__schema__(:association, :contacts_phone_numbers)
%Ecto.Associations.Has{assoc: UcxCallout.ContactPhoneNumber,
 assoc_key: :phone_number_id, cardinality: :many,
 field: :contacts_phone_numbers, owner: UcxCallout.PhoneNumber, owner_key: :id}
```
