defmodule Aquir.Accounts.Commands.RegisterUser do

  defstruct [
    :uuid,
    :username,
    :email,
    :password,
    :hashed_password
  ]
end
