defmodule ExAdmin.Builder do
  alias ExAdmin.Builder.Server

  use ExActor.GenServer

  defmacro build(name, do: block) do
    quote location: :keep do
      name = unquote(name)
      module = unquote(__MODULE__)
      import unquote(__MODULE__)
      Server.start_buffer name
      unquote(block)
      result = Server.get_buffer(name) |> Enum.reverse
      Server.stop_buffer(name)
      result
    end
  end

  defmacro put(name, value) do
    quote do
      Server.put_buffer unquote(name), unquote(value)
    end
  end

  
end
