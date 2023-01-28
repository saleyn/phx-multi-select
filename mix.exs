defmodule MultiSelect.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_multi_select,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: ["lib"],
      deps: deps()
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

  # Specifies your project dependencies.
  defp deps do
    [
      {:phoenix,             "~> 1.7.0-rc.0", override: true},
      {:phoenix_html,        "~> 3.0"},
      {:phoenix_live_view,   "~> 0.18.3"},
    ]
  end
end
