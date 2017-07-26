defmodule Ivar.Mixfile do
  use Mix.Project

  def project do
    [app: :ivar,
     version: "0.9.0",
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:mimerl, "~> 1.0.2"},
      
      # optional deps
      {:poison, "~> 2.0 or ~> 3.0", optional: true},
      
      # dev/test deps
      {:ex_doc, "~> 0.15.0", only: :dev},
      {:credo, "~> 0.7.2", only: [:dev, :test]}
    ]
  end

  defp description do
    "Ivar is an adapter based HTTP client that provides the ability to build composable HTTP requests"
  end

  defp package do
    [name: :ivar,
     maintainers: ["swelham"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/swelham/ivar"}]
  end
end
