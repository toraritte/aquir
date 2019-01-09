defmodule Aquir.Commanded.Router do
  use Commanded.Commands.Router

  # alias Aquir.Accounts.Aggregates.User
  # alias Aquir.Accounts.Commands.{
  #   RegisterUser,
  #   ResetPassword,
  # }

  # # Accounts
  # dispatch [RegisterUser],  to: User, identity: :user_id
  # dispatch [ResetPassword], to: User, identity: :email
end
