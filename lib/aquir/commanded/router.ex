defmodule Aquir.Commanded.Router do
  use Commanded.Commands.Router

  # 2019-01-16_0604 TODO (Move to Users context)
  @doc """
  It would  probably be  prudent to  move this  to the
  account  context. We'll  see how  interesting things
  will become with more contexts, so this is a maybe.
  """

  # 2019-01-16_0814 TODO (CompositeRouter)
  @doc """
  Related to 2019-01-16_0604, just what I was thinking
  about when moving the router out of `Users`.
  https://github.com/commanded/commanded/blob/master/guides/Commands.md#composite-command-routers
  """

  # 2019-01-18_0455 TODO (Add Commanded middlewares)

  alias Aquir.Users.Aggregates, as: Agg
  alias Aquir.Users.Commands,   as: Com

  dispatch [Com.RegisterUser],
    to: Agg.User,
    identity: :user_id

  identify Agg.Credential, by: :credential_id
  dispatch [
      Com.AddUsernamePasswordCredential,
      Com.ResetPassword,
    ],
    to: Agg.Credential
end
