defmodule Aquir.Accounts.Aggregates.User do

  defstruct [
    :uuid,
    :username,
    :email,
    :hashed_password
  ]

  alias __MODULE__

  alias Aquir.Accounts.Commands.RegisterUser

  alias Aquir.Accounts.Events.UserRegistered

  @doc """
  Register a new user.
  """
  def execute(%User{uuid: nil}, %RegisterUser{} = r) do
    %UserRegistered{
      uuid:     r.uuid,
      username: r.username,
      email:    r.email,
      hashed_password: r.hashed_password
    }
  end

  def apply(%User{} = user, %UserRegistered{} = r) do
    %User{ user |
      uuid:     r.uuid,
      username: r.username,
      email:    r.email,
      hashed_password: r.hashed_password
    }
  end
end
