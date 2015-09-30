defmodule <%= base %>.ExAdmin.Dashboard do
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
  end
end
