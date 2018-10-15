defmodule Aquir.Accounts.Events.UserRegistered do

  @derive [Poison.Encoder]

  defstruct [
    :user_uuid,
    :email,
    :hashed_password
  ]
end
