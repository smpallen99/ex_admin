defmodule ExAdmin.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_admin,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:phoenix, "~> 0.14"},
      {:ecto, "~> 0.12", override: true },
      {:phoenix_ecto, "~> 0.5"},
      {:cowboy, "~> 1.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 1.1"},
      {:phoenix_live_reload, "~> 0.4", only: :dev},
      {:factory_girl_elixir, "~> 0.1.1"},
      {:pavlov, "~> 0.1.2", only: :test},
      {:inflex, "~> 1.0"},
      {:sass_elixir, "~> 0.0.1"}, 
      {:ex_form, github: "smpallen99/ex_form"},
      {:xain, github: "smpallen99/xain", override: true},
      {:scrivener, "~> 0.4.0"}, 
      {:csvlixir, "~> 1.0.0"},
      {:exactor, "~>1.0.0"}, 
    ]
  end
end
