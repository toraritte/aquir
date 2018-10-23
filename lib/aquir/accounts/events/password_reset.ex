defmodule Aquir.Accounts.Events.PasswordReset do

  @derive [Poison.Encoder]

  defstruct [
    :email,
    :password_hash,
  ]
end
