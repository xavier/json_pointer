defmodule JsonPointer.Mixfile do
  use Mix.Project

  def project do
    [app: :json_pointer,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
     source_url: "https://github.com/xavier/json_pointer",
     homepage_url: "https://github.com/xavier/json_pointer"]
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
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev}]
  end

  defp description do
    "Implementation of RFC 6901 which defines a string syntax for identifying a specific value within a JSON document"
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     contributors: ["Xavier Defrang"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/xavier/json_pointer"}
   ]
  end
end
