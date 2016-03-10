defmodule ExAdmin.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_admin,
     version: "0.5.0",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "ExAdmin",
     docs: [extras: ["README.md"]],
     deps: deps]
  end

  def application do
    [applications: [:logger, :ex_queb]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]
  
  defp deps do
    [
      {:decimal, "~> 1.0"},
      {:phoenix, "~> 1.1.2", override: true},
      {:ecto, "~> 1.1", override: true },
      {:phoenix_ecto, "~> 2.0"},
      {:cowboy, "~> 1.0"},
      {:mariaex, "~> 0.5"},
      {:phoenix_html, "~> 2.3", override: true},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:factory_girl_elixir, "~> 0.1.1"},
      {:pavlov, "~> 0.1.2", only: :test},
      {:inflex, github: "smpallen99/inflex"},
      {:ex_form, github: "smpallen99/ex_form"},
      {:xain, github: "smpallen99/xain", override: true},
      {:scrivener, "~> 0.10.0"}, 
      {:csvlixir, "~> 1.0.0"},
      {:exactor, "~>2.2.0"}, 
      {:ex_doc, "~>0.10.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_queb, github: "E-MetroTel/ex_queb"},
    ]
  end
end
