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

    * --no-brunch - Write assets to priv/static instead of web/static/
    * --no-assets - Skip the assets
    * --no-config - Skip the config
    * --no-dashboard - Skip the dashboard
    * --no-route - Skip the route instructions
  """

  # @shortdoc "Install ExAdmin"

  use Mix.Task
  import Mix.ExAdmin.Utils
  import ExAdmin.Gettext

  @boolean_switchs ~w(assets config route dashboard brunch)a
  @switches Enum.map(@boolean_switchs, &({&1, :boolean}))

  defmodule Config do
    @moduledoc false
    defstruct route: true, assets: true, dashboard: true,
      package_path: nil, config: true, brunch: true,
      brunch_path: nil, assets_path: nil, vendor_path: nil,
      phx: false
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
    config_path = Path.join ~w(config config.exs)
    unless File.exists? config_path do
      Mix.raise """
      Can't find #{config_path}
      """
    end
    config
  end
  defp check_config(config), do: config

  defp check_assets(%{assets: true, brunch: true} = config) do
    config
    |> check_and_set_brunch_path_phx
    |> check_and_set_assets_path
  end
  defp check_assets(%{assets: true} = config) do
    check_and_set_assets_path(config)
    # path = Path.join ~w(priv static)
    # unless File.exists?(path) do
    #   Mix.raise """
    #   Can't find #{path}
    #   """
    # end
    # config
  end
  defp check_assets(config), do: config

  defp check_and_set_brunch_path_phx(config) do
    if File.exists? "assets/brunch-config.js" do
      struct(config, brunch_path: "assets/brunch-config.js", phx: true)
    else
      check_and_set_brunch_path(config)
    end
  end

  defp check_and_set_assets_path(config) do
    cond do
      File.exists?(Path.join(~w(assets css))) ->
        struct config,
          vendor_path: Path.join(~w(assets vendor)),
          assets_path: Path.join(~w(assets static))
      File.exists?(Path.join(~w(web static))) ->
        struct config,
          vendor_path: Path.join(~w(web static vendor)),
          assets_path: Path.join(~w(web static assets))
      true ->
        Mix.raise """
        Can't find assets path!
        """
    end
  end

  def check_and_set_brunch_path(config) do
    unless File.exists? "brunch-config.js" do
      Mix.raise """
      Can't find brunch-config.js
      """
    end
    struct(config, brunch_path: "brunch-config.js")
  end

  def do_assets(%Config{assets: true, brunch: true, brunch_path: brunch_path} = config) do
    base_path = Path.join(~w(priv static))

    File.mkdir_p config.vendor_path
    File.mkdir_p Path.join(config.assets_path, "fonts")
    File.mkdir_p Path.join([config.assets_path | ~w{images ex_admin datepicker}])

    status_msg("creating", "css files")
    ~w(admin_lte2.css admin_lte2.css.map active_admin.css.css active_admin.css.css.map)
    |> Enum.each(&(copy_vendor config, base_path, "css", &1))

    status_msg("creating", "js files")
    ~w(jquery.min.js admin_lte2.js jquery.min.js.map admin_lte2.js.map)
    ++ ~w(ex_admin_common.js ex_admin_common.js.map)
    |> Enum.each(&(copy_vendor config, base_path, "js", &1))

    copy_vendor_r(config, base_path, "fonts")
    copy_vendor_r(config, base_path, "images")

    case File.read brunch_path do
      {:ok, file} ->
        File.write! brunch_path, file <> brunch_instructions(config)
      error ->
        Mix.raise """
        Could not open brunch-config.js file. #{inspect error}
        """
    end
    config
  end
  def do_assets(%Config{assets: true} = config) do
    base = ~w(priv static)
    base_path = Path.join(base)

    Enum.each ~w(fonts css js), &(File.mkdir_p Path.join(base ++ [&1]))
    File.mkdir_p Path.join(~w{priv static images ex_admin datepicker})
    File.mkdir_p Path.join(~w(web admin))

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
    Mix.shell.info """

    Add the admin routes to your web/router.ex:

      use ExAdmin.Router
      # your app's routes
      scope "/admin", ExAdmin do
        pipe_through :browser
        admin_routes()
      end
    """
    config
  end
  def do_route(config), do: config

  def do_config(%Config{config: true} = config) do
    status_msg("updating", "config/config.exs")
    dest_path = Path.join [File.cwd! | ~w(config)]
    dest_file_path = Path.join dest_path, "config.exs"
    source = File.read!(dest_file_path)
    ""
    |> config_xain(config, source)
    |> config_write(config, dest_file_path, source)
  end
  def do_config(config), do: config

  defp config_xain(append, _config, source) do
    unless String.contains? source, ":xain, :after_callback" do
      append <> """
      config :xain, :after_callback, {Phoenix.HTML, :raw}

      """
    else
      notice_msg("skipping", "xain config. It already exists.")
      append
    end
  end

  defp config_write("", config, _dest_file_path, _source), do: config
  defp config_write(append, config, dest_file_path, source) do
    File.write! dest_file_path, source <> "\n" <> append
    config
  end

  def do_dashboard(%Config{dashboard: true} = config) do
    web_path = web_path()
    dest_path = Path.join(web_path, "admin")
    dest_file_path = Path.join dest_path, "dashboard.ex"
    source = Path.join([config.package_path | ~w(priv templates admin.install dashboard.exs)] )
    |> EEx.eval_file([base: get_module(),
      title_txt: (gettext "Dashboard"),
      welcome_txt: (gettext "Welcome to ExAdmin. This is the default dashboard page."),
      add_txt: (gettext "To add dashboard sections, checkout '${web_path}/admin/dashboards.ex'", web_path: web_path)
      ])

    if File.exists?(dest_file_path) do
      notice_msg "skipping", "#{dest_file_path}. It already exists."
    else
      status_msg "creating", dest_file_path
      File.mkdir_p dest_path
      File.write! dest_file_path, source
      dashboard_instructions(config)
    end
    config
  end
  def do_dashboard(config), do: config

  def dashboard_instructions(config) do
    base = get_module()
    module = if config.phx, do: "#{base}.Web", else: base
    Mix.shell.info """

    Remember to update your config file:

      config :ex_admin,
        repo: #{base}.Repo,
        module: #{module},
        modules: [
          #{base}.ExAdmin.Dashboard,
        ]
    """
  end

  def do_paging(config) do
    base = get_module()

    Mix.shell.info """

    Add Scrivener paging to your Repo:

      defmodule #{base}.Repo do
        use Ecto.Repo, otp_app: :#{String.downcase base}
        use Scrivener, page_size: 10  # <--- add this
      end
    """
    config
  end


  def do_assets_instructions(%{assets: true, brunch: true} = config) do
    Mix.shell.info """

    Check the bottom of your brunch-config.js file.

      Instructions for adding the ExAdmin assets have been added.
    """
    config
  end
  def do_assets_instructions(config), do: config

  defp copy_r(base_path, path) do
    File.cp_r Path.join([get_package_path(), base_path, path]),
            Path.join([File.cwd!, base_path, path])
    base_path
  end

  defp copy_file(base_path, path, file_name) do
    File.cp Path.join([get_package_path(), base_path, path, file_name]),
            Path.join([File.cwd!, base_path, path, file_name])
    base_path
  end

  defp copy_vendor(config, from_path, path, filename) do
    File.cp Path.join([get_package_path(), from_path, path, filename]),
            Path.join(config.vendor_path, filename)
  end
  defp copy_vendor_r(config, base_path, path) do
    File.cp_r Path.join([get_package_path(), base_path, path]),
            Path.join(config.assets_path, path)
  end

  def brunch_instructions(config) do
    js_match = if config.phx, do: "js", else: "web\\/static\\/js"
    css_match = if config.phx, do: "css", else: "web\\/static\\/css"
    css_path = if config.phx, do: "css", else: "web/static/css"
    vendor_path = if config.phx, do: "vendor", else: "web/static/vendor"

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
    //         "js/app.js": /^(#{js_match})|(node_modules)/,
    //         "js/ex_admin_common.js": ["#{vendor_path}/ex_admin_common.js"],
    //         "js/admin_lte2.js": ["#{vendor_path}/admin_lte2.js"],
    //         "js/jquery.min.js": ["#{vendor_path}/jquery.min.js"],
    //       }
    //     },
    //
    // Replace
    //
    //     stylesheets: {
    //       joinTo: "css/app.css",
    //       order: {
    //         after: ["#{css_path}/app.css"] // concat app.css last
    //       }
    //     },
    //
    // With
    //
    //     stylesheets: {
    //       joinTo: {
    //         "css/app.css": /^(#{css_match})/,
    //         "css/admin_lte2.css": ["#{vendor_path}/admin_lte2.css"],
    //         "css/active_admin.css.css": ["#{vendor_path}/active_admin.css.css"],
    //       },
    //       order: {
    //         after: ["#{css_path}/app.css"] // concat app.css last
    //       }
    //     },
    //
    """
  end

  defp parse_args(args) do
    {opts, _values, _} = OptionParser.parse args, switches: @switches
    Enum.reduce opts, %Config{package_path: get_package_path()}, fn
      {key, value}, config ->
        if key in Map.keys(config) do
          struct(config, [{key, value}])
        else
          raise_option key
        end
      other, _config ->
        raise_option inspect(other)
    end
  end

  defp raise_option(option) do
    Mix.raise """
    Invalid option --#{option}
    """
  end

end
