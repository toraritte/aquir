# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :aquir,
  ecto_repos: [Aquir.Repo]

# Configures the endpoint
config :aquir, AquirWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4sVHJg+wq9JmCAxTLXAmL9+892cCPqzSeTJb7UEDOIsDWk+8gMmivfeEJTM8EZEI",
  render_errors: [view: AquirWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Aquir.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :commanded,
  event_store_adapter: Commanded.EventStore.Adapters.EventStore

# config :commanded_ecto_projections, repo: Aquir.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
