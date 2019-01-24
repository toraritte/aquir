defmodule Aquir.Accounts.Events.UserRegistered do

  # From "Building Conduit":  "Commanded uses the poison
  # pure Elixir JSON library  to serialize events in the
  # database."
  @derive Jason.Encoder

  defstruct [
    :user_id,
    :name,
    :email,
  ]
end
