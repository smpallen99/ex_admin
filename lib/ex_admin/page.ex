defmodule ExAdmin.Page do

  defmacro __using__(_) do
    quote do
      import ExAdmin.form, except: [content: 1]
      import unquote(__MODULE__)
    end
  end


  defmacro content(do: block) do
    quote do
    end

  end
  
end
