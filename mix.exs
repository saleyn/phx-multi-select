defmodule MultiSelect.MixProject do
  use Mix.Project

  def project do
    [
      app:           :phoenix_multi_select,
      version:       "0.1.1",
      elixir:        "~> 1.14",
      elixirc_paths: ["lib"],
      deps:          deps(),
      package:       package(),

      # Docs
      name:         "MultiSelect",
      description:  "A MultiSelect component for Phoenix LiveView",
      homepage_url: "http://github.com/saleyn/phx-multi-select",
      authors:      ["Serge Aleynikov"],
      docs:         [
        main:       "Phoenix.LiveView.Components.MultiSelect", # The main page in the docs
        extras:     ["README.md"]
      ],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: []
    ]
  end

  defp package() do
    [
      # These are the default files included in the package
      licenses: ["BSD"],
      links:    %{"GitHub" => "https://github.com/saleyn/phx-multi-select"},
      files:    ~w(lib assets mix.exs Makefile README* LICENSE* CHANGELOG*
        example/assets example/config example/lib example/Makefile
        example/mix.exs example/priv/gettext example/README* example/test)
    ]
  end

  # Specifies your project dependencies.
  defp deps do
    [
      {:phoenix,             "~> 1.7"},
      {:phoenix_html,        "~> 4.1"},
      {:phoenix_live_view,   "~> 0.20"},
      {:ex_doc,              "~> 0.31", only: :dev, runtime: false},
    ]
  end
end
