Code.require_file("../../mix_helpers.exs", __DIR__)

defmodule Mix.Tasks.ExAdmin.InstallTest do
  use ExUnit.Case
  import MixHelper
  alias Mix.Tasks.Admin.Install

  @css_files ~w(admin_lte2.css admin_lte2.css.map active_admin.css.css) ++
               ~w(active_admin.css.css.map)
  @js_files ~w(jquery.min.js admin_lte2.js jquery.min.js.map admin_lte2.js.map) ++
              ~w(ex_admin_common.js ex_admin_common.js.map)

  @font_files ~w(FontAwesome.otf fontawesome-webfont.eot fontawesome-webfont.svg fontawesome-webfont.ttf fontawesome-webfont.woff fontawesome-webfont.woff2 ionicons.eot ionicons.svg ionicons.ttf ionicons.woff)
  @image_files ~w(admin_notes_icon.png glyphicons-halflings-white.png glyphicons-halflings.png orderable.png)
  @datepicker_files ~w(datepicker-header-bg.png datepicker-input-icon.png datepicker-next-link-icon.png datepicker-nipple.png datepicker-prev-link-icon.png)

  defp assert_or_refute_file(:assert, path) do
    assert_file(path)
  end

  defp assert_or_refute_file(:refute, path) do
    refute_file(path)
  end

  defp assert_brunch_assets(mode \\ :assert) do
    Enum.each(@js_files ++ @css_files, fn file ->
      assert_or_refute_file(mode, Path.join(~w(web static vendor) ++ [file]))
    end)

    Enum.each(@font_files, fn file ->
      assert_or_refute_file(mode, Path.join(~w(web static assets fonts) ++ [file]))
    end)

    dest_path = ~w(web static assets images ex_admin)

    Enum.each(@image_files, fn file ->
      assert_or_refute_file(mode, Path.join(dest_path ++ [file]))
    end)

    dest_path = dest_path ++ ["datepicker"]

    Enum.each(@datepicker_files, fn file ->
      assert_or_refute_file(mode, Path.join(dest_path ++ [file]))
    end)
  end

  defp assert_no_brunch_assets(mode \\ :assert) do
    Enum.each(@css_files, fn file ->
      assert_or_refute_file(mode, Path.join(~w(priv static css) ++ [file]))
    end)

    Enum.each(@js_files, fn file ->
      assert_or_refute_file(mode, Path.join(~w(priv static js) ++ [file]))
    end)

    Enum.each(@font_files, fn file ->
      assert_or_refute_file(mode, Path.join(~w(priv static fonts) ++ [file]))
    end)

    dest_path = ~w(priv static images ex_admin)

    Enum.each(@image_files, fn file ->
      assert_or_refute_file(mode, Path.join(dest_path ++ [file]))
    end)

    dest_path = dest_path ++ ["datepicker"]

    Enum.each(@datepicker_files, fn file ->
      assert_or_refute_file(mode, Path.join(dest_path ++ [file]))
    end)
  end

  def assert_dashboard do
    path = Path.join(~w(web admin dashboard.ex))

    assert_file(path, fn file ->
      assert file =~ "defmodule ExAdmin.ExAdmin.Dashboard do"
      assert file =~ "Welcome to ExAdmin."
    end)
  end

  setup do
    Mix.Task.clear()
    :ok
  end

  def create_config do
    File.mkdir("config")
    File.touch(Path.join(~w(config config.exs)))
  end

  def create_brunch_config do
    File.touch("brunch-config.js")
  end

  def create_priv_static do
    File.mkdir_p(Path.join(~w(priv static)))
  end

  test "installs with brunch" do
    in_tmp("installs with brunch", fn ->
      Logger.disable(self())
      create_config()
      create_brunch_config()

      Mix.Tasks.Admin.Install.run([])

      assert_file("config/config.exs", fn file ->
        assert file =~ "config :xain, :after_callback, {Phoenix.HTML, :raw}"
      end)

      assert_brunch_assets()

      assert_file("brunch-config.js", fn file ->
        assert file =~ Install.brunch_instructions()
      end)
    end)
  end

  test "no brunch install" do
    in_tmp("no brunch install", fn ->
      create_config()
      create_priv_static()

      Mix.Tasks.Admin.Install.run(["--no-brunch"])

      assert_file("config/config.exs", fn file ->
        assert file =~ "config :xain, :after_callback, {Phoenix.HTML, :raw}"
      end)

      assert_no_brunch_assets()
    end)
  end

  test "no config install" do
    in_tmp("no config install", fn ->
      create_config()
      create_brunch_config()

      Mix.Tasks.Admin.Install.run(["--no-config"])

      assert_file("config/config.exs", fn file ->
        assert file =~ ""
      end)

      assert_brunch_assets()
    end)
  end

  test "no assets install" do
    in_tmp("no assets install", fn ->
      create_config()

      Mix.Tasks.Admin.Install.run(["--no-assets"])

      assert_dashboard()

      assert_file("config/config.exs", fn file ->
        assert file =~ "config :xain, :after_callback, {Phoenix.HTML, :raw}"
      end)

      assert_brunch_assets(:refute)
      assert_no_brunch_assets(:refute)
    end)
  end

  test "no dashboard no config install" do
    in_tmp("no dashboard no config install", fn ->
      create_config()
      create_brunch_config()

      Mix.Tasks.Admin.Install.run(~w(--no-dashboard --no-config))

      assert_file("config/config.exs", fn file ->
        assert file =~ ""
      end)

      refute_file(Path.join(~w(web admin dashboard.ex)))

      assert_brunch_assets()
    end)
  end
end
