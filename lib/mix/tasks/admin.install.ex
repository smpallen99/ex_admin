defmodule Mix.Tasks.Admin.Install do
  @moduledoc """
  Install ExAdmin

  Installs the files required to use ExAdmin.

  """

  @shortdoc "Install ExAdmin"

  use Mix.Task

  defmodule Config do
    defstruct route: true, assets: true
  end

  def run(args) do
    do_run(args)
  end

  def do_run(args) do
    parse_args(args)
    |> do_install()
  end

  def do_install(config) do
    config
    |> do_assets
    |> do_route
  end

  def do_assets(%Config{assets: true} = config) do
    base_path = Path.join(~w(priv static))

    status_msg("coping", "css files")
    ~w(active_admin.css active_admin.css.css)
    |> Enum.each(&(copy_file base_path, "css", &1))

    status_msg("coping", "image files")
    ~w(glyphicons-halflings-white.png glyphicons-halflings.png)
    |> Enum.each(&(copy_file base_path, "images", &1))

    config
  end
  def do_assets(config) do
    config
  end

  def do_route(%Config{route: true} = config) do

    IO.puts ""
    IO.puts "Add the admin routes to your web/router.ex:"
    IO.puts ""
    IO.puts "    admin_routes :admin"
    IO.puts ""
    config
  end
  def do_route(config) do
    config
  end

  defp copy_file(base_path, path, file_name) do
    File.cp Path.join([package_path, base_path, path, file_name]), 
            Path.join([File.cwd!, base_path, path, file_name])
    base_path
  end

  defp parse_args(_args) do
    %Config{}
  end

  defp package_path do
    __ENV__.file
    |> Path.dirname
    |> String.split("/lib/mix/tasks")
    |> hd
  end

  @doc "Print a status message to the console"
  def status_msg(status, message), 
    do: IO.puts "#{IO.ANSI.green}* #{status}#{IO.ANSI.reset} #{message}"

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
