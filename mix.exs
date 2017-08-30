defmodule Ivar.Mixfile do
  use Mix.Project

  def project do
    [app: :ivar,
     version: "0.10.1",
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

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
