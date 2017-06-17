defmodule Prolly.Mixfile do
  use Mix.Project

  def project do
    [app: :Prolly,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Prolly.Application, []}]
  end

  defp deps do
    [{:array_vector, "~> 0.1"},
     {:benchee, "~> 0.9.0", only: :dev},
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
