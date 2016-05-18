defmodule ExAdmin.Page do
  @moduledoc """
  Define pages in ExAdmin that don't render models, like a dashboard
  page.

  """

  import ExAdmin.DslUtils
  import ExAdmin.Theme.Helpers

  defmacro __using__(_) do
    quote do
      import ExAdmin.Form, except: [content: 1]
      import unquote(__MODULE__)
    end
  end


  @doc """
  Display contents on a page. Use Xain markup to create the page.

  For example, the dashboard page:

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
  """
  defmacro content(opts \\ [], do: block) do

    bdy = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [opts: escape(opts), bdy: escape(bdy)] do
      def page_view(var!(conn)) do
        import Kernel, except: [div: 2, to_string: 1]
        import ExAdmin.ViewHelpers
        use Xain
        markup do
          unquote(bdy)
        end
      end
    end

  end

  defmacro columns(do: block) do
    quote do
      var!(columns, ExAdmin.Show) = []
      var!(columns, ExAdmin.Page) = []
      unquote(block)
      cols = var!(columns, ExAdmin.Page) |> Enum.reverse
      theme_module(Page).columns(cols)
      var!(columns, ExAdmin.Page) = []
    end
  end

  defmacro column([do: block]) do
    quote do
      html = markup :nested do
        unquote(block)
      end
      var!(columns, ExAdmin.Page) = [html | var!(columns, ExAdmin.Page)]
    end
  end

end
