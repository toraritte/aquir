defmodule Aquir.Accounts.Events.PasswordReset do

  @derive [Poison.Encoder]

  defstruct [
    :user_uuid,
    :password_hash,
  ]
end
