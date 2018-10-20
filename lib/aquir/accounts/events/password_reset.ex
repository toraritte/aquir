defmodule Aquir.Accounts.Events.PasswordReset do

  @derive [Poison.Encoder]

  defstruct [
    :user_id,
    :password_hash,
  ]
end
