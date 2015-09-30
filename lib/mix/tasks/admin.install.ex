defmodule Mix.Tasks.Admin.Install do
  @moduledoc """
  Install ExAdmin

  Installs the files required to use ExAdmin.

  """

  @shortdoc "Install ExAdmin"

  use Mix.Task
  import Mix.ExAdmin.Utils

  defmodule Config do
    defstruct route: true, assets: true, dashboard: true, 
      package_path: nil
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
    |> do_dashboard
    |> do_route
  end

  def do_assets(%Config{assets: true} = config) do
    base_path = Path.join(~w(priv static))

    status_msg("creating", "css files")
    ~w(active_admin.css active_admin.css.css)
    |> Enum.each(&(copy_file base_path, "css", &1))

    status_msg("creating", "image files")
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

  def do_dashboard(%Config{dashboard: true} = config) do
    dest_path = Path.join [File.cwd! | ~w(web admin)]
    dest_file_path = Path.join dest_path, "dashboard.ex"
    source = Path.join([config.package_path | ~w(priv templates admin.install dashboard.exs)] )
    |> EEx.eval_file(base: get_module)
    status_msg "creating", Path.join(~w(web admin dashboard.ex))
    File.mkdir dest_path
    File.write! dest_file_path, source
    dashboard_instructions
    config
  end
  def do_dashboard(config) do
    config
  end

  def dashboard_instructions do
    base = get_module
    IO.puts ""
    IO.puts "Remember to update your config file with the dashboard module"
    IO.puts ""
    IO.puts """    
        config :ex_admin, :modules, [
          #{base}.ExAdmin.Dashboard,
        ]

    """
  end

  defp copy_file(base_path, path, file_name) do
    File.cp Path.join([get_package_path, base_path, path, file_name]), 
            Path.join([File.cwd!, base_path, path, file_name])
    base_path
  end

  defp parse_args(_args) do
    %Config{package_path: get_package_path}
  end


end
