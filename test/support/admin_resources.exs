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
