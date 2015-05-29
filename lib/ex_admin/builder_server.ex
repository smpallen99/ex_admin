defmodule ExAdmin.Builder.Server do
  defmodule Context do
    defstruct buffers: HashDict.new

    def put_buffer(r, name, content) when is_atom(name) do
      new_buffer = put_buffer(Dict.get(r.buffers, name), content)
      struct(r, buffers: Dict.put(r.buffers, name, new_buffer))
    end
    defp put_buffer(buffer, content), do: [content | buffer]

    def get_buffer(r, name, default \\ nil) do
      Dict.get(r.buffers, name, default)
    end
  end

  use ExActor.GenServer, export: :ex_admin_buffer

  definit do
    initial_state %Context{}
  end

  defcall start_buffer(name), state: cx do
    struct(cx, buffers: Dict.put(cx.buffers, name, []))
    |> set_and_reply(:ok)
  end

  defcall stop_buffer(name), state: cx do
    struct(cx, buffers: Dict.delete(cx.buffers, name))
    |> set_and_reply(:ok)
  end

  defcast put_buffer(name, content), state: cx do
    Context.put_buffer(cx, name, content)
    |> new_state
  end

  defcall get_buffer(name), state: cx do
    Context.get_buffer(cx, name)
    |> reply
  end

end
