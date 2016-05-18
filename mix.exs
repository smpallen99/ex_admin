defmodule ExAdmin.Mixfile do
  use Mix.Project

  @version "0.7.7-dev"

  def project do
    [ app: :ex_admin,
      version: @version,
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "ExAdmin",
      docs: [extras: ["README.md"], main: "ExAdmin"],
      deps: deps,
      package: package,
      description: """
      An Elixir Phoenix Auto Administration Package.
      """
    ]
  end

  def application do
    [ applications: applications(Mix.env)]
  end

  defp applications(:test) do
    [:plug | applications(:prod)]
  end
  defp applications(_) do
    [:phoenix, :ecto, :logger, :ex_queb, :xain]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:decimal, "~> 1.0"},
      {:phoenix, "~> 1.1"},
      {:ecto, "~> 1.1"},
      {:phoenix_ecto, "~> 2.0"},
      {:postgrex, ">= 0.0.0", only: :test},
      {:cowboy, "~> 1.0"},
      {:phoenix_html, "~> 2.5"},
      {:factory_girl_elixir, "~> 0.1.1"},
      {:inflex, "~> 1.5"},
      {:xain, "~> 0.5.3"},
      {:scrivener, "~> 1.0"},
      {:csvlixir, "~> 1.0.0"},
      {:exactor, "~> 2.2.0"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_queb, "~> 0.1"},
    ]
  end

  defp package do
    [ maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/ex_admin" },
      files: ~w(lib priv web README.md package.json mix.exs LICENSE brunch-config.js AdminLte-LICENSE)]
  end
end
