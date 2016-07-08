defmodule <%= base %>.ExAdmin.Dashboard do
  use ExAdmin.Register

  register_page "Dashboard" do
    menu priority: 1, label: "<%= title_txt %>"
    content do
      div ".blank_slate_container#dashboard_default_message" do
        span ".blank_slate" do
          span "<%= welcome_txt %>"
          small "<%= add_txt %>"
        end
      end
    end
  end
end
