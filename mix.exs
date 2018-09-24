defmodule MastaniServer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mastani_server,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      dialyzer: [plt_add_deps: :transitive, ignore_warnings: ".dialyzer_ignore.exs"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
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
      extra_applications: [
        :corsica,
        :ex_unit,
        :logger,
        :runtime_tools,
        :faker,
        :scrivener_ecto,
        :timex,
        :sentry
      ]
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
      {:phoenix, "~> 1.3.4"},
      {:phoenix_pubsub, "~> 1.1.0"},
      {:phoenix_ecto, "~> 3.4.0"},
      {:ecto, "~> 2.2.10"},
      {:postgrex, ">= 0.13.5"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      # GraphQl tool
      {:absinthe, "~> 1.4.13"},
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
      {:scrivener_ecto, git: "https://github.com/mastani-stack/scrivener_ecto", override: true},
      {:guardian, "~> 1.0"},
      {:timex, "~> 3.2.1"},
      {:dataloader, "~> 1.0.2"},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:apollo_tracing, "~> 0.4.1"},
      {:pre_commit, "~> 0.3.4"},
      {:inch_ex, "~> 1.0", only: [:dev, :test]},
      {:short_maps, "~> 0.1.1"},
      {:jason, "~> 1.0"},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev, :mock], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:sentry, "~> 6.4"}
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
      "test.coverage": ["coveralls.html"],
      "test.coverage.short": ["coveralls"],
      "doc.report": ["inch.report"],
      lint: ["credo --strict"],
      "lint.static": ["dialyzer --format dialyxir"]
    ]
  end
end
