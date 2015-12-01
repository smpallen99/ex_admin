defmodule ExAdmin.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_admin,
     version: "0.3.2",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "ExAdmin",
     docs: [extras: ["README.md"]],
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]
  
  defp deps do
    [
      {:phoenix, "~> 1.0.2", override: true},
      {:ecto, "~> 1.0.3", override: true },
      {:phoenix_ecto, "~> 1.1"},
      {:cowboy, "~> 1.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.1", override: true},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:factory_girl_elixir, "~> 0.1.1"},
      {:pavlov, "~> 0.1.2", only: :test},
      {:inflex, github: "smpallen99/inflex"},
      {:ex_form, github: "smpallen99/ex_form"},
      {:xain, github: "smpallen99/xain", override: true},
      {:scrivener, "~> 0.10.0"}, 
      {:csvlixir, "~> 1.0.0"},
      {:exactor, "~>1.0.0"}, 
      {:ex_doc, "~>0.10.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_queb, path: "../ex_queb"},
    ]
  end
end
