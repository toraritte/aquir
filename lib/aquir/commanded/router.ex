defmodule Aquir.Commanded.Router do
  use Commanded.Commands.Router

  alias Aquir.Accounts.Aggregates, as: A
  alias Aquir.Accounts.Commands,   as: C

  # Accounts.User
  dispatch [C.RegisterUser],
    to: A.User,
    identity: :user_id

  dispatch [C.AddUsernamePasswordCredential],
    to: A.Credential,
    identity: :credential_id

  dispatch [C.ResetPassword],
    to: A.Credential,
    identity: :credential_id
end
