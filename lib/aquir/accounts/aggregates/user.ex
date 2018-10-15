defmodule Aquir.Accounts.Aggregates.User do

  defstruct [
    :uuid,
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
      user_uuid: r.user_uuid,
      email:     r.email,
      hashed_password: r.hashed_password
    }
  end

  def apply(%User{} = user, %UserRegistered{} = r) do
    %User{ user |
      uuid:     r.user_uuid,
      email:    r.email,
      hashed_password: r.hashed_password
    }
  end
end
