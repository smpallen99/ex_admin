defmodule TestExAdmin.ExAdmin.Dashboard do
  use ExAdmin.Register

  register_page "Dashboard" do
    menu priority: 1, label: "Dashboard"
    content do
      div ".blank_slate_container#dashboard_default_message" do
        span ".blank_slate" do
          span "Welcome to ExAdmin. This is the default dashboard page."
          small "To add dashboard sections, checkout 'web/admin/dashboards.ex'"
        end
      end
    end
    sidebar "Test Sidebar" do
      div do
        text "This is a test."
      end
    end
  end
end

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
        markup_contents do
          h3 "First table"
        end
        markup_contents do
          p "With some No-ID entries"
        end
        table_for user.noids do
          column "Full name", fn(item) -> text "#{item.name} (#{item.company})" end
        end
        table_for user.noids do
          column "Full name", fn(item) -> text "#{item.name} (#{item.company})" end
        end
        markup_contents do
          h3 "^^ Second table"
        end
      end
    end
    form user do
      inputs "User Details" do
        input user, :name
        input user, :email
      end

      inputs "Roles" do
        inputs :roles, as: :check_boxes, collection: TestExAdmin.Role.all
      end

    end
    query do
      %{all: [preload: [:noids, :roles]]}
    end
  end
end

defmodule TestExAdmin.ExAdmin.Product do
  use ExAdmin.Register
  alias TestExAdmin.Repo
  alias TestExAdmin.User

  register_resource TestExAdmin.Product do
    controller do
      after_filter :do_after, only: [:create, :update]

      def do_after(conn, params, resource, :create) do
        user = Repo.all(User) |> hd
        resource = Product.changeset(resource, %{user_id: user.id})
        |> Repo.update!
        {Plug.Conn.assign(conn, :product, resource), params, resource}
      end
      def do_after(conn, _params, _resource, :update) do
        Plug.Conn.assign(conn, :answer, 42)
      end
    end
  end
end
defmodule TestExAdmin.ExAdmin.Simple do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
  end
end

defmodule TestExAdmin.ExAdmin.Contact do
  use ExAdmin.Register

  register_resource TestExAdmin.Contact do

    form contact do
      inputs do
        input contact, :first_name
        input contact, :last_name
      end

      inputs "Phone Numbers" do
        has_many contact, :phone_numbers, fn(p) ->
          input p, :label, collection: TestExAdmin.PhoneNumber.labels
          input p, :number
        end
      end
    end
  end
end
