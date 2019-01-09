defmodule Aquir.Commanded.Router do
  use Commanded.Commands.Router

  alias Aquir.Accounts.Aggregates.User
  alias Aquir.Accounts.Commands, as: C

  # Accounts.User
  dispatch [C.RegisterUser],  to: User, identity: :user_id
  # dispatch [C.ResetPassword], to: User, identity: :user_id
end
