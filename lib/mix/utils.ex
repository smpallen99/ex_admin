defmodule Mix.ExAdmin.Utils do

  def get_package_path do
    __ENV__.file
    |> Path.dirname
    |> String.split("/lib/mix")
    |> hd
  end

  def get_module do
    Mix.Project.get
    |> Module.split
    |> Enum.reverse
    |> Enum.at(1)
  end

  def web_path() do
    path1 = Path.join ["lib", to_string(Mix.Phoenix.otp_app())]
    path2 = "web"
    cond do
      File.exists? path1 -> path1
      File.exists? path2 -> path2
      true ->
        raise "Could not find web path '#{path1}'."
    end
  end

  @doc "Print a status message to the console"
  def status_msg(status, message),
    do: IO.puts "#{IO.ANSI.green}* #{status}#{IO.ANSI.reset} #{message}"
  def notice_msg(status, message),
    do: IO.puts "#{IO.ANSI.yellow}* #{status}#{IO.ANSI.reset} #{message}"

  @doc "Print an informational message without color"
  def debug(message), do: IO.puts "==> #{message}"
  @doc "Print an informational message in green"
  def info(message),  do: IO.puts "==> #{IO.ANSI.green}#{message}#{IO.ANSI.reset}"
  @doc "Print a warning message in yellow"
  def warn(message),  do: IO.puts "==> #{IO.ANSI.yellow}#{message}#{IO.ANSI.reset}"
  @doc "Print a notice in yellow"
  def notice(message), do: IO.puts "#{IO.ANSI.yellow}#{message}#{IO.ANSI.reset}"
  @doc "Print an error message in red"
  def error(message), do: IO.puts "==> #{IO.ANSI.red}#{message}#{IO.ANSI.reset}"
end
