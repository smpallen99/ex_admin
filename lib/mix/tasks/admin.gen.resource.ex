defmodule Mix.Tasks.Admin.Gen.Resource do
  @moduledoc """
  Generate an ExAdmin Resource file

  Creates a resource file used to define the administration pages
  for the auto administration feature

      mix admin.gen.resource Survey

  Creates a web/admin/survey.ex file.

  """

  @shortdoc "Generate a Resource file"

  use Mix.Task
  import Mix.ExAdmin.Utils

  defmodule Config do
    @moduledoc false
    defstruct module: nil, package_path: nil
  end

  def run(args) do
    parse_args(args)
    |> copy_file
  end

  defp copy_file(%Config{module: module, package_path: package_path} = config) do
    filename = Macro.underscore(module) <> ".ex"
    dest_path = Path.join(~w(web admin))
    dest_file_path = Path.join(dest_path, filename)
    source_file = Path.join([package_path | ~w(priv templates admin.gen.resource resource.exs)])
    source = source_file |> EEx.eval_file(base: get_module(), resource: module)
    status_msg("creating", dest_file_path)
    File.write!(dest_file_path, source)
    display_instructions(config)
  end

  defp display_instructions(config) do
    base = get_module()
    IO.puts("")
    IO.puts("Remember to update your config file with the resource module")
    IO.puts("")

    IO.puts("""
        config :ex_admin, :modules, [
          #{base}.ExAdmin.Dashboard,
          ...
          #{base}.ExAdmin.#{config.module}
        ]

    """)
  end

  defp parse_args([module]) do
    %Config{module: module, package_path: get_package_path()}
  end
end
