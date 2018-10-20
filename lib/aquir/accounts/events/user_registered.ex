defmodule Aquir.Accounts.Events.UserRegistered do

  @derive [Poison.Encoder]

  defstruct [
    :user_id,
    :email,
    :password_hash
  ]
end
