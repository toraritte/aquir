defmodule Aquir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :aquir,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Aquir.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :eventstore,
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix,             "~> 1.4.0"},
      {:phoenix_pubsub,      "~> 1.1"},
      {:phoenix_ecto,        "~> 4.0"},
      {:ecto_sql,            "~> 3.0"},
      {:postgrex,            ">= 0.0.0"},
      {:phoenix_html,        "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext,             "~> 0.11"},
      {:plug_cowboy,         "~> 2.0"},
      {:comeonin,            "~> 4.1"},
      # https://security.stackexchange.com/questions/4781/
      {:bcrypt_elixir,       "~> 1.1"},
      {:poison,              "~> 3.0 or ~> 4.0"},

      # {:commanded, "~> 0.15"},
      # {:commanded, github: "toraritte/commanded", branch: "master"},
      # {:commanded, path: "../commanded", override: true},
      {:commanded,
        github:   "toraritte/commanded",
        branch:   "make-application-more-idiomatic-2",
      },

      # The official lib includes `commanded/eventstore`!
      # {:commanded_eventstore_adapter, "~> 0.3"},
      {:commanded_eventstore_adapter,
        github: "toraritte/commanded-eventstore-adapter",
        branch: "remove-child-spec-0",
      },

      # {:commanded_ecto_projections,   "~> 0.7"},
      {:commanded_ecto_projections,
        github: "toraritte/commanded-ecto-projections",
        branch: "master",
      },
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
