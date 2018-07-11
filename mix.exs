defmodule MastaniServer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mastani_server,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MastaniServer.Application, []},
      extra_applications: [:corsica, :logger, :runtime_tools, :faker, :scrivener_ecto, :timex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:mock), do: ["lib", "priv/mock", "test/support"]
  defp elixirc_paths(_), do: ["lib", "test/support"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0.2"},
      {:phoenix_ecto, "~> 3.3.0"},
      {:ecto, "~> 2.2.9"},
      {:postgrex, ">= 0.13.5"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      # GraphQl tool
      {:absinthe, "~> 1.4.12"},
      {:absinthe_ecto, "~> 0.1.3"},
      # Plug support for Absinthe
      # {:absinthe_plug, "~> 1.4.4"},
      # treat parse error as status "200"
      {:absinthe_plug, git: "https://github.com/mastani-stack/absinthe_plug", override: true},
      # Password hashing lib
      {:comeonin, "~> 4.0.3"},
      # Argon2 password hashing algorithm
      # {:argon2_elixir, "~> 1.2"},
      # CORS
      {:corsica, "~> 1.1.1"},
      {:tesla, "~> 0.10.0"},
      # for fake data in test env
      {:faker, "~> 0.9"},
      {:scrivener_ecto, "~> 1.3.0"},
      {:guardian, "~> 1.0"},
      {:timex, "~> 3.2.1"},
      {:dataloader, "~> 1.0.2"},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:apollo_tracing, "~> 0.4.1"},
      {:pre_commit, "~> 0.3.4"},
      {:inch_ex, "~> 0.5", only: [:dev, :test]},
      {:short_maps, "~> 0.1.1"},
      {:jason, "~> 1.0"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    # test.watch is powerd by: https://github.com/lpil/mix-test.watch
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/mock/user_seeds.exs"],
      # "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "doc.report": ["inch.report"]
    ]
  end
end
