defmodule ExAdmin.Page do
  import ExAdmin.DslUtils

  defmacro __using__(_) do
    quote do
      import ExAdmin.Form, except: [content: 1]
      import unquote(__MODULE__)
    end
  end


  defmacro content(opts \\ [], do: block) do

    bdy = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [opts: escape(opts), bdy: escape(bdy)] do

      def page_view(conn) do
        import Kernel, except: [div: 2, to_string: 1]
        use Xain
        markup do
          unquote(bdy)
        end
      end
    end

  end
  
end
