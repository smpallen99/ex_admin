defmodule TestExAdmin.ExAdmin.Noid do
  use ExAdmin.Register

  register_resource TestExAdmin.Noid do
    query do
      %{all: [preload: [:user]]}
    end
  end
end

defmodule TestExAdmin.ExAdmin.User do
  use ExAdmin.Register

  register_resource TestExAdmin.User do
    show user do
      panel "No IDs" do
        table_for user.noids do
          column "Full name", fn(item) -> text "#{item.name} (#{item.company})" end
        end
      end
    end
    query do
      %{all: [preload: [:noids]]}
    end
  end
end
defmodule TestExAdmin.ExAdmin.Product do
  use ExAdmin.Register

  register_resource TestExAdmin.Product do
  end
end
