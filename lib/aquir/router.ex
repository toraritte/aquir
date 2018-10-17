defmodule Aquir.Router do
  use Commanded.Commands.Router

  alias Aquir.Accounts.Aggregates.User
  alias Aquir.Accounts.Commands.{
    RegisterUser,
    ResetPassword,
  }

    dispatch [RegisterUser],  to: User, identity: :user_uuid
    dispatch [ResetPassword], to: User, identity: :user_uuid
end
