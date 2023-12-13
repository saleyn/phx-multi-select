defmodule MultiSelectExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :multi_select_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      prune_code_paths: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MultiSelectExample.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      {:phoenix,              "~> 1.7.0-rc.2", override: true},
      {:phoenix_html,         "~> 3.0"},
      {:phoenix_live_reload,  "~> 1.2",        only: :dev},
      {:phoenix_live_view,    "~> 0.18.3"},
      {:heroicons,            "~> 0.5"},
      {:esbuild,              "~> 0.5",    runtime: Mix.env() == :dev},
      {:tailwind,             "~> 0.1.8",  runtime: Mix.env() == :dev},
      {:faker,                "~> 0.17",   runtime: false},
      {:gettext,              "~> 0.20"},
      {:jason,                "~> 1.2"},
      {:plug_cowboy,          "~> 2.5"},
      #{:phoenix_multi_select, git: "https://github.com/saleyn/phx-multi-select.git", branch: "main"},
      {:phoenix_multi_select, path: "../", in_umbrella: true},
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.deploy"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
