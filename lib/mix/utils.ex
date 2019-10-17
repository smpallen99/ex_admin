defmodule Mix.ExAdmin.Utils do
  def get_package_path do
    __ENV__.file
    |> Path.dirname()
    |> String.split("/lib/mix")
    |> hd
  end

  def get_module do
    Mix.Project.get()
    |> Module.split()
    |> Enum.reverse()
    |> Enum.at(1)
  end

  def get_module_underscored_name do
    get_module() |> Macro.underscore()
  end

  def get_web_path do
    get_module_underscored_name() <> "_web"
  end

  @doc "Print a status message to the console"
  def status_msg(status, message),
    do: IO.puts("#{IO.ANSI.green()}* #{status}#{IO.ANSI.reset()} #{message}")

  def notice_msg(status, message),
    do: IO.puts("#{IO.ANSI.yellow()}* #{status}#{IO.ANSI.reset()} #{message}")

  @doc "Print an informational message without color"
  def debug(message), do: IO.puts("==> #{message}")
  @doc "Print an informational message in green"
  def info(message), do: IO.puts("==> #{IO.ANSI.green()}#{message}#{IO.ANSI.reset()}")
  @doc "Print a warning message in yellow"
  def warn(message), do: IO.puts("==> #{IO.ANSI.yellow()}#{message}#{IO.ANSI.reset()}")
  @doc "Print a notice in yellow"
  def notice(message), do: IO.puts("#{IO.ANSI.yellow()}#{message}#{IO.ANSI.reset()}")
  @doc "Print an error message in red"
  def error(message), do: IO.puts("==> #{IO.ANSI.red()}#{message}#{IO.ANSI.reset()}")
end
