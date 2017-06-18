defmodule Prolly.Mixfile do
  use Mix.Project

  def project do
    [app: :prolly,
     version: "0.2.0",
     elixir: "~> 1.4",
     package: package(),
     description: "Probabilistic data structures for Elixir",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:array_vector, "~> 0.1"},
     {:benchee, "~> 0.9.0", only: :dev},
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [maintainers: ["Clark Kampfe"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/ckampfe/prolly"}]
  end
end
