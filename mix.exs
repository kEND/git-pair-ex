defmodule GitPairEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :git_pair_ex,
      version: "VERSION" |> File.read!() |> String.trim(),
      elixir: "~> 1.13.3",
      escript: escript_config(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript_config do
    [
      main_module: GitPairEx.CLI,
      name: "git-pair",
      comment: "Manage co-authers for git",
      path: "/usr/local/bin/git-pair"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
