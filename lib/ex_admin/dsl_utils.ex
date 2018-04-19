defmodule ExAdmin.DslUtils do
  @moduledoc false

  def add_to_attribute(mod, attr_name, key, value) do
    items = Module.get_attribute(mod, attr_name)
    Module.put_attribute(mod, attr_name, [{key, value} | items])
  end

  def escape(var) do
    Macro.escape(var, unquote: true)
  end

  def fun_to_opts(opts, fun) do
    case {opts, fun} do
      {fun, _} when is_function(fun) ->
        [fun: fun]

      {opts, nil} ->
        opts

      {opts, fun} ->
        [{:fun, fun} | opts]
    end
    |> Enum.into(%{})
  end
end
