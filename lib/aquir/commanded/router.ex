defmodule Aquir.Commanded.Router do
  use Commanded.Commands.Router

  # 2019-01-16_0604 TODO (Move to Accounts context)
  @doc """
  It would  probably be  prudent to  move this  to the
  account  context. We'll  see how  interesting things
  will become with more contexts, so this is a maybe.
  """
  alias Aquir.Accounts.Aggregates, as: A
  alias Aquir.Accounts.Commands,   as: C

  dispatch [C.RegisterUser],
    to: A.User,
    identity: :user_id

  identify A.Credential, by: :credential_id
  dispatch [
      C.AddUsernamePasswordCredential,
      C.ResetPassword,
    ],
    to: A.Credential
end
