defmodule Mix.Tasks.Admin.Install do
  @moduledoc """
  Install ExAdmin supporting files.

      mix admin.install

  # Defaults:

    * assets - copy js, css, and image files
    * brunch - append instructions to brunch-config.js
    * config - add configuration to config/config.exs
    * dashboard - create a default dashboard
    * route - display instructions to add the admin routes

  ## Options:

    * --no-brunch - Write assets to priv/static instead of assets/static/
    * --no-assets - Skip the assets
    * --no-config - Skip the config
    * --no-dashboard - Skip the dashboard
    * --no-route - Skip the route instructions
  """

  # @shortdoc "Install ExAdmin"

  use Mix.Task
  import Mix.ExAdmin.Utils
  import ExAdmin.Gettext

  @boolean_switchs ~w(assets config route dashboard brunch)
  @switches Enum.map(@boolean_switchs, &{&1, :boolean})

  defmodule Config do
    @moduledoc false
    defstruct route: true,
              assets: true,
              dashboard: true,
              package_path: nil,
              config: true,
              brunch: true
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
    |> check_project
    |> do_assets
    |> do_config
    |> do_dashboard
    |> do_route
    |> do_paging
    |> do_assets_instructions
  end

  def check_project(config) do
    config
    |> check_config
    |> check_assets
  end

  defp check_config(%{config: true} = config) do
    config_path = Path.join(~w(config config.exs))

    unless File.exists?(config_path) do
      Mix.raise("""
      Can't find #{config_path}
      """)
    end

    config
  end

  defp check_config(config), do: config

  defp check_assets(%{assets: true, brunch: true} = config) do
    brunch_path = Path.join(~w(assets brunch-config.js))
    IO.inspect(brunch_path)

    unless File.exists?(brunch_path) do
      Mix.raise("""
      Can't find brunch-config.js
      """)
    end

    config
  end

  defp check_assets(%{assets: true} = config) do
    path = Path.join(~w(priv static))

    unless File.exists?(path) do
      Mix.raise("""
      Can't find #{path}
      """)
    end

    config
  end

  defp check_assets(config), do: config

  def do_assets(%Config{assets: true, brunch: true} = config) do
    base_path = Path.join(~w(priv static))
    brunch_config_path = Path.join(~w{assets brunch-config.js})

    File.mkdir_p(Path.join(~w{assets static vendor}))
    File.mkdir_p(Path.join(~w{assets static assets fonts}))
    File.mkdir_p(Path.join(~w{assets static assets images ex_admin datepicker}))

    status_msg("creating", "css files")

    ~w(admin_lte2.css admin_lte2.css.map active_admin.css.css active_admin.css.css.map)
    |> Enum.each(&copy_vendor(base_path, "css", &1))

    status_msg("creating", "js files")

    (~w(jquery.min.js admin_lte2.js jquery.min.js.map admin_lte2.js.map) ++
       ~w(ex_admin_common.js ex_admin_common.js.map))
    |> Enum.each(&copy_vendor(base_path, "js", &1))

    copy_vendor_r(base_path, "fonts")
    copy_vendor_r(base_path, "images")

    case File.read(brunch_config_path) do
      {:ok, file} ->
        File.write!(brunch_config_path, file <> brunch_instructions())

      error ->
        Mix.raise("""
        Could not open brunch-config.js file. #{inspect(error)}
        """)
    end

    config
  end

  def do_assets(%Config{assets: true} = config) do
    base = ~w(priv static)
    base_path = Path.join(base)
    app_web_path = get_web_path()

    Enum.each(~w(fonts css js), &File.mkdir_p(Path.join(base ++ [&1])))
    File.mkdir_p(Path.join(~w{priv static images ex_admin datepicker}))
    File.mkdir_p(Path.join(["lib", app_web_path, "admin"]))

    status_msg("creating", "css files")

    ~w(admin_lte2.css admin_lte2.css.map active_admin.css.css active_admin.css.css.map)
    |> Enum.each(&copy_file(base_path, "css", &1))

    status_msg("creating", "js files")

    (~w(jquery.min.js admin_lte2.js jquery.min.js.map admin_lte2.js.map) ++
       ~w(ex_admin_common.js ex_admin_common.js.map))
    |> Enum.each(&copy_file(base_path, "js", &1))

    copy_r(base_path, "fonts")
    copy_r(base_path, "images")

    config
  end

  def do_assets(config) do
    config
  end

  def do_route(%Config{route: true} = config) do
    app_web_path = get_web_path()

    Mix.shell().info("""

    Add the admin routes to your lib/#{app_web_path}/router.ex:

      use ExAdmin.Router
      # your app's routes
      scope "/admin", ExAdmin do
        pipe_through :browser
        admin_routes()
      end
    """)

    config
  end

  def do_route(config), do: config

  def do_config(%Config{config: true} = config) do
    status_msg("updating", "config/config.exs")
    dest_path = Path.join([File.cwd!() | ~w(config)])
    dest_file_path = Path.join(dest_path, "config.exs")
    source = File.read!(dest_file_path)

    ""
    |> config_xain(config, source)
    |> config_write(config, dest_file_path, source)
  end

  def do_config(config), do: config

  defp config_xain(append, _config, source) do
    unless String.contains?(source, ":xain, :after_callback") do
      append <>
        """
        config :xain, :after_callback, {Phoenix.HTML, :raw}

        """
    else
      notice_msg("skipping", "xain config. It already exists.")
      append
    end
  end

  defp config_write("", config, _dest_file_path, _source), do: config

  defp config_write(append, config, dest_file_path, source) do
    File.write!(dest_file_path, source <> "\n" <> append)
    config
  end

  def do_dashboard(%Config{dashboard: true} = config) do
    app_web_path = get_web_path()
    dest_path = Path.join([File.cwd!() | ["lib", app_web_path, "admin"]])
    dest_file_path = Path.join(dest_path, "dashboard.ex")

    source =
      Path.join([config.package_path | ~w(priv templates admin.install dashboard.exs)])
      |> EEx.eval_file(
        base: get_module(),
        title_txt: gettext("Dashboard"),
        welcome_txt: gettext("Welcome to ExAdmin. This is the default dashboard page."),
        add_txt:
          gettext("To add dashboard sections, checkout 'lib/my_app_web/admin/dashboards.ex'")
      )

    file = Path.join(["lib", app_web_path, "admin", "dashboard.ex"])

    if File.exists?(file) do
      notice_msg("skipping", "#{file}. It already exists.")
    else
      status_msg("creating", file)
      File.mkdir_p(dest_path)
      File.write!(dest_file_path, source)
      dashboard_instructions()
    end

    config
  end

  def do_dashboard(config), do: config

  def dashboard_instructions do
    base = get_module()

    Mix.shell().info("""

    Remember to update your config file:

      config :ex_admin,
        repo: #{base}.Repo,
        module: #{base},
        modules: [
          #{base}.ExAdmin.Dashboard,
        ]
    """)
  end

  def do_paging(config) do
    module_name = get_module()
    base = get_module_underscored_name()

    Mix.shell().info("""

    Add Scrivener paging to your Repo:

      defmodule #{module_name}.Repo do
        use Ecto.Repo, otp_app: :#{base}
        use Scrivener, page_size: 10  # <--- add this
      end
    """)

    config
  end

  def do_assets_instructions(%{assets: true, brunch: true} = config) do
    Mix.shell().info("""

    Check the bottom of your brunch-config.js file.

      Instructions for adding the ExAdmin assets have been added.
    """)

    config
  end

  def do_assets_instructions(config), do: config

  defp copy_r(base_path, path) do
    File.cp_r(
      Path.join([get_package_path(), base_path, path]),
      Path.join([File.cwd!(), base_path, path])
    )

    base_path
  end

  defp copy_file(base_path, path, file_name) do
    File.cp(
      Path.join([get_package_path(), base_path, path, file_name]),
      Path.join([File.cwd!(), base_path, path, file_name])
    )

    base_path
  end

  defp copy_vendor(from_path, path, filename) do
    File.cp(
      Path.join([get_package_path(), from_path, path, filename]),
      Path.join([File.cwd!(), "assets", "static", "vendor", filename])
    )
  end

  defp copy_vendor_r(base_path, path) do
    File.cp_r(
      Path.join([get_package_path(), base_path, path]),
      Path.join([File.cwd!(), "assets", "static", "assets", path])
    )
  end

  def brunch_instructions do
    """

    // To add the ExAdmin generated assets to your brunch build, do the following:
    //
    // Replace
    //
    //     javascripts: {
    //       joinTo: "js/app.js"
    //     },
    //
    // With
    //
    //     javascripts: {
    //       joinTo: {
    //         "js/app.js": /^(static\\/js)|(node_modules)/,
    //         "js/ex_admin_common.js": ["vendor/ex_admin_common.js"],
    //         "js/admin_lte2.js": ["vendor/admin_lte2.js"],
    //         "js/jquery.min.js": ["vendor/jquery.min.js"],
    //       }
    //     },
    //
    // Replace
    //
    //     stylesheets: {
    //       joinTo: "css/app.css",
    //       order: {
    //         after: ["css/app.css"] // concat app.css last
    //       }
    //     },
    //
    // With
    //
    //     stylesheets: {
    //       joinTo: {
    //         "css/app.css": /^(static\\/css)/,
    //         "css/admin_lte2.css": ["vendor/admin_lte2.css"],
    //         "css/active_admin.css.css": ["vendor/active_admin.css.css"],
    //       },
    //       order: {
    //         after: ["css/app.css"] // concat app.css last
    //       }
    //     },
    //
    """
  end

  defp parse_args(args) do
    {opts, _values, _} = OptionParser.parse(args, switches: @switches)

    Enum.reduce(opts, %Config{package_path: get_package_path()}, fn
      {key, value}, config ->
        if key in Map.keys(config) do
          struct(config, [{key, value}])
        else
          raise_option(key)
        end

      other, _config ->
        raise_option(inspect(other))
    end)
  end

  defp raise_option(option) do
    Mix.raise("""
    Invalid option --#{option}
    """)
  end
end
