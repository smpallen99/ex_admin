defmodule Mix.Tasks.Admin.Install do
  @moduledoc """
  Install ExAdmin supporting files.

      mix admin.install

  # Defaults:

    * assets - copy js, css, and image files
    * config - add configuration to config/config.exs
    * dashboard - create a default dashboard
    * route - display instructions to add the admin routes

  ## Options:

    * --no-assets - Skip the assets
    * --no-config - Skip the config
    * --no-dashboard - Skip the dashboard
    * --no-route - Skip the route instructions
  """

  # @shortdoc "Install ExAdmin"

  use Mix.Task
  import Mix.ExAdmin.Utils

  defmodule Config do
    defstruct route: true, assets: true, dashboard: true,
      package_path: nil, config: true
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
    |> do_config
    |> do_dashboard
    |> do_route
    |> do_paging
    |> do_endpoint
  end

  def do_assets(%Config{assets: true} = config) do
    base_path = Path.join(~w(priv static))

    status_msg("creating", "css files")
    ~w(admin_lte2.css admin_lte2.css.map active_admin.css.css active_admin.css.css.map)
    |> Enum.each(&(copy_file base_path, "css", &1))

    status_msg("creating", "js files")
    ~w(jquery.min.js admin_lte2.js jquery.min.js.map admin_lte2.js.map)
    ++ ~w(ex_admin_common.js ex_admin_common.js.map)
    |> Enum.each(&(copy_file base_path, "js", &1))

    copy_r(base_path, "fonts")
    copy_r(base_path, "images")

    config
  end
  def do_assets(config) do
    config
  end

  def do_route(%Config{route: true} = config) do
    IO.puts ""
    IO.puts "Add the admin routes to your web/router.ex:"
    IO.puts ""
    IO.puts "    use ExAdmin.Router\n"
    IO.puts "    # your app's routes\n"
    IO.puts "    scope \"/admin\", ExAdmin do"
    IO.puts "      pipe_through :browser"
    IO.puts "      admin_routes"
    IO.puts "    end"
    config
  end
  def do_route(config) do
    config
  end

  def do_endpoint(config) do
    base = get_module
    IO.puts ""
    IO.puts "Add 'themes' to your lib/#{String.downcase base}/endpoint.ex file:"
    IO.puts """

  plug Plug.Static,
    at: "/", from: :#{String.downcase base}, gzip: false,
    only: ~w(css fonts images js themes favicon.ico robots.txt)
                                 ------

 """
    config
  end

  def do_config(%Config{config: true} = config) do
    status_msg("updating", "config/config.exs")
    dest_path = Path.join [File.cwd! | ~w(config)]
    dest_file_path = Path.join dest_path, "config.exs"
    source = File.read!(dest_file_path)
    ""
    |> config_xain(config, source)
    |> config_write(config, dest_file_path, source)
  end
  def do_config(config) do
    config
  end

  defp config_xain(append, _config, source) do
    unless String.contains? source, ":xain, :after_callback" do
      append <> """
      config :xain, :after_callback, {Phoenix.HTML, :raw}

      """
    else
      status_msg("skipping", "xain config. It already exists.")
      append
    end
  end

  defp config_write("", config, _dest_file_path, _source), do: config
  defp config_write(append, config, dest_file_path, source) do
    File.write! dest_file_path, source <> "\n" <> append
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
    IO.puts "Remember to update your config file:"
    IO.puts ""
    IO.puts """
        config :ex_admin,
          repo: #{base}.Repo,
          module: #{base},
          modules: [
            #{base}.ExAdmin.Dashboard,
          ]
    """
  end

  def do_paging(config) do
    base = get_module

    IO.puts ""
    IO.puts "Add Scrivener paging to your Repo:"
    IO.puts ""
    IO.puts "    defmodule #{base}.Repo do"
    IO.puts "      use Ecto.Repo, otp_app: :#{String.downcase base}"
    IO.puts "      use Scrivener, page_size: 10"
    IO.puts "    end"
    config
  end

  defp copy_r(base_path, path) do
    File.cp_r Path.join([get_package_path, base_path, path]),
            Path.join([File.cwd!, base_path, path])
    base_path
  end

  defp copy_file(base_path, path, file_name) do
    File.cp Path.join([get_package_path, base_path, path, file_name]),
            Path.join([File.cwd!, base_path, path, file_name])
    base_path
  end

  defp parse_args(args) do
    {opts, _values, _} = OptionParser.parse args, switches:
      [assets: :boolean, config: :boolean, route: :boolean, dashboard: :boolean]
    Enum.reduce opts, %Config{package_path: get_package_path}, fn(item, config) ->
      case item do
        {key, value} ->
          if key in Map.keys(config) do
            struct(config, [{key, value}])
          else
            IO.puts "Incorrect option: #{key}"
            config
          end
        _default -> config
      end
    end
  end

end
