defmodule Mix.Tasks.Admin.Install do
  @moduledoc """
  Install ExAdmin

  Installs the files required to use ExAdmin, including:

    * copying css and image files
    * adding configuration to config/config.exs
    * adding a default dashboard
    * displaying instructions to add the admin routes

  The --renderer renderer option can be used to add a renderer
  to the config file. For example

      mix admin.install --renderer swift

  Installs ExAdmin and sets the swift renderer for text-to-speech
  """

  # @shortdoc "Install ExAdmin"

  use Mix.Task
  import Mix.ExAdmin.Utils

  defmodule Config do
    defstruct route: true, assets: true, dashboard: true, 
      package_path: nil, config: true, renderer: false
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

  def do_config(%Config{config: true} = config) do
    status_msg("updating", "config/config.exs")
    dest_path = Path.join [File.cwd! | ~w(config)]
    dest_file_path = Path.join dest_path, "config.exs"
    source = File.read!(dest_file_path)
    append = ""
    |> config_template_engines(config, source)
    |> config_xain(config, source)
    |> config_renderer(config, source)
    |> config_write(config, dest_file_path, source)
  end
  def do_config(config) do
    config
  end

  defp config_renderer(append, %{renderer: false} = config, source) do
    append
  end
  defp config_renderer(append, config, source) do
    unless String.contains? source, ":speak_ex, :renderer" do
      append <> """
      config :speak_ex, :renderer, :#{config.renderer}
      """
    else
      append
    end
  end
  defp config_template_engines(append, _config, source) do
    unless String.contains? source, "haml: PhoenixHaml.Engine" do
      append <> """
      config :phoenix, :template_engines,
          haml: PhoenixHaml.Engine,
          eex: Phoenix.Template.EExEngine

      """
    else
      append
    end
  end
  defp config_xain(append, _config, source) do
    unless String.contains? source, ":xain, :quote" do
      append <> """
      config :xain, :quote, "'"
      config :xain, :after_callback, &Phoenix.HTML.raw/1

      """
    else
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

  defp parse_args(args) do
    {opts, values, _} = OptionParser.parse args
    Enum.reduce opts, %Config{package_path: get_package_path}, fn(item, config) -> 
      case item do
        {key, value} -> 
          if key in Map.keys(config) do
            struct(config, [{key, value}])
          else
            IO.puts "incorrect option: #{key}"
            config
          end
        _ -> config
      end
    end
  end


end
