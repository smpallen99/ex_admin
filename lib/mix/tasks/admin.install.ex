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
  end

  def do_assets(%Config{assets: true} = config) do
    base_path = Path.join(~w(priv static))

    status_msg("creating", "css files")
    ~w(active_admin.css active_admin.css.css)
    |> Enum.each(&(copy_file base_path, "css", &1))

    status_msg("creating", "js files")
    ~w(jquery-ujs.js.js jquery.js)
    |> Enum.each(&(copy_file base_path, "js", &1))
    do_active_admin_js(base_path)

    status_msg("creating", "image files")
    do_active_admin_images(base_path)

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
    IO.puts "    use ExAdmin.Router"
    IO.puts "    admin_routes :admin"
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
    ""
    |> config_xain(config, source)
    |> config_write(config, dest_file_path, source)
  end
  def do_config(config) do
    config
  end

  defp config_xain(append, _config, source) do
    unless String.contains? source, ":xain, :quote" do
      append <> """
      config :xain, :quote, "'"
      config :xain, :after_callback, &Phoenix.HTML.raw/1

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
  defp copy_file(base_path, path, file_name) do
    File.cp Path.join([get_package_path, base_path, path, file_name]), 
            Path.join([File.cwd!, base_path, path, file_name])
    base_path
  end

  defp do_active_admin_images(base_path) do
    aa_rel_path = Path.join "images", "active_admin"
    aa_images_path = Path.join(
      [File.cwd!, base_path, aa_rel_path])

    if File.exists? aa_images_path do
      status_msg("skipping", 
        aa_rel_path <> " files. Directory already exists.")
    else
      :ok = File.mkdir(aa_images_path)
      ~w(admin_notes_icon.png orderable.png)
      |> Enum.each(&(copy_file base_path, aa_rel_path, &1))

      aa_dp_rel_path = Path.join aa_rel_path, "datepicker"
      aa_dp_images_path = Path.join aa_images_path, "datepicker" 

      :ok = File.mkdir(aa_dp_images_path)
      ~w(datepicker-header-bg.png datepicker-input-icon.png) ++ 
      ~w(datepicker-next-link-icon.png datepicker-nipple.png) ++ 
      ~w(datepicker-prev-link-icon.png)
      |> Enum.each(&(copy_file base_path, aa_dp_rel_path, &1))

    end
  end

  defp do_active_admin_js(base_path) do
    src_path = Path.join([get_package_path | ~w(web static js active_admin src)])
    fname = "application.js.js"
    source = get_file_banner(fname)
    source = source <> File.read!(Path.join([src_path, fname])) <> "\n\n"

    lib_files = ~w(batch_actions.js.js dropdown-menu.js.js has_many.js.js) ++  
      ~w(table-checkbox-toggler.js.js checkbox-toggler.js.js flash.js.js) ++ 
      ~w(modal_dialog.js.js popover.js.js per_page.js.js)

    source = 
      ""
      |> read_active_admin_js(src_path, ~w(application.js.js base.js.js)) 
      |> read_active_admin_js(Path.join([src_path, "ext"]), ~w(jquery-ui.js.js jquery.js.js))
      |> read_active_admin_js(Path.join([src_path, "lib"]), lib_files)

    File.write! Path.join([base_path, "js", "active_admin.js"]), source
  end

  defp read_active_admin_js(source, src_path, files) do
    files 
    |> Enum.reduce(source, fn(fname, acc) -> 
      acc <> get_file_banner(fname) <> File.read!(Path.join([src_path, fname])) <> "\n\n"
    end)
  end

  defp get_file_banner(file_name) do
    "// File: " <> file_name <> "\n"
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
