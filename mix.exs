defmodule ExAdmin.Mixfile do
  use Mix.Project

  @version "0.9.0-dev"

  def project do
    [ app: :ex_admin,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "ExAdmin",
      docs: [extras: ["README.md"], main: "ExAdmin"],
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      description: """
      An Elixir Phoenix Auto Administration Package.
      """
    ]
  end

  def application do
    [ applications: applications(Mix.env)]
  end

  defp applications(:test) do
    [:plug, :cowboy | applications(:prod)]
  end
  defp applications(_) do
    [:gettext, :phoenix, :ecto, :inflex, :scrivener, :scrivener_ecto, :csvlixir, :logger, :ex_queb, :xain]
  end
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:decimal, "~> 1.0"},
      {:phoenix, "~> 1.2"},
      {:phoenix_html, "~> 2.6"},
      {:ecto, "~> 2.1"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, "~> 0.13", only: :test},
      {:floki, "~> 0.8", only: :test},
      {:cowboy, "~> 1.0"},
      {:inflex, "~> 1.7"},
      {:scrivener_ecto, "~> 1.1"},
      {:xain, "~> 0.6"},
      {:csvlixir, "~> 1.0.0"},
      {:exactor, "~> 2.2.0"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_queb, "~> 1.0"},
      {:excoveralls, "~> 0.5", only: :test},
      {:gettext, "~> 0.11"},
      {:hound, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [ maintainers: ["Stephen Pallen", "Roman Smirnov"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/ex_admin" },
      files: ~w(lib priv web README.md package.json mix.exs LICENSE brunch-config.js AdminLte-LICENSE)]
  end
end
