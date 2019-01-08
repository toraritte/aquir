defmodule Aquir.Accounts.Aggregates.Credential.Events.PasswordReset do

  @derive [Poison.Encoder]
  defstruct [
    :user_id
    :username,
    :password_hash,
  ]
end
