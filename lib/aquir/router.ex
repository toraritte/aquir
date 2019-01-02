defmodule Aquir.CommandedRouter do
  use Commanded.Commands.Router

  alias Aquir.Accounts.Aggregates.User
  alias Aquir.Accounts.Commands.{
    RegisterUser,
    ResetPassword,
  }

  @doc """
  NOTE 2018-10-19_2246
  Commanded.Middleware is  currently implemented  as a
  behaviour with before  and after dispatch callbacks,
  and every middleware in a  router is called for each
  command.  Pattern match  is needed  in the  specific
  middlewares, but this  way it is hard  to know which
  middleware is used for which command unless one goes
  through every  middleware. Also,  there may  be that
  one  middleware  is  needed   only  for  one  single
  command.
  TODO PROPOSAL: Use something  similar to `pipeline/2` and
  'pipe_through/1` in  Phoenix. It won't be  simple as
  there are  default middleware  implementations added
  in Commanded.Commands.Router.
  """

    dispatch [RegisterUser],  to: User, identity: :user_id
    dispatch [ResetPassword], to: User, identity: :email
end
