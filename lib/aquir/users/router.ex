defmodule Aquir.Users.Router do
  use Commanded.Commands.Router

  # 2019-01-18_0455 TODO (Add Commanded middlewares)

  alias Aquir.Users.Aggregates, as: A
  alias Aquir.Users.Commands,   as: C

  dispatch [C.RegisterUser],
    to: A.User,
    identity: :user_id

  # identify A.Credential, by: :credential_id
  dispatch [
      C.AddUsernamePasswordCredential,
      C.ResetPassword,
    ],
    to: A.Credential,
    identity: :credential_id
end
