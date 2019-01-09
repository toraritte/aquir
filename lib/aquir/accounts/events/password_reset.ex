defmodule Aquir.Accounts.Events.PasswordReset do

  @derive [Poison.Encoder]
  defstruct [
    :user_id,
    :username,
    :password_hash,
  ]
end
