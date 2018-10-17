defmodule Aquir.Accounts.Aggregates.User do
  require Logger

  @moduledoc """
  NOTE 2018-10-14_2339
  Instill these slides: https://www.slideshare.net/andrewhao/building-beautiful-systems-with-phoenix-contexts-and-domaindriven-design

  So  if credentials  would need  to be  added at  one
  point  (to support  different auth  mechanisms, e.g.
  OAuth), then  this would  probably be  the aggregate
  root (i.e.,  aggregates/user.ex) and  the supporting
  objects would go to the "user" directory:

  aggregates/
  |- user/
  |   |- credential.ex
  |   |- etc.ex
  |- user.ex

  It's still fuzzy how the schemas would look like, but
  the  domain is  complex  enough that  there will  be
  plenty of opportunity to figure it out.
  """

  defstruct [
    :uuid,
    :email,
    :password_hash
  ]

  alias Aquir.Accounts

  alias Accounts.Aggregates.{
    User,
    Support,
  }

  alias Accounts.Commands.{
    RegisterUser,
    ResetPassword,
  }

  alias Accounts.Events.{
    UserRegistered,
    PasswordReset,
  }

  @doc """
  Register a new user.

  NOTE 2018-10-14_2348
  An  aggregate   instance  (i.e.,  a  stream)   is  a
  gen_server,  and the  first argument  to `execute/2`
  and `apply/2`  are the state  of the process.  It is
  still unclear  how these  functions get  called, but
  this makes the most sense at the moment.

  NOTE 2018-10-15_2316
  The  `execute/2`  clauses  are  simple,  because  by
  the  time the  command  gets here,  it already  went
  through validation  via changesets in  context (such
  as `accounts.ex`).
  """
  def execute(%User{uuid: nil}, %RegisterUser{} = command) do
    Support.convert_similar_structs(command, UserRegistered)
  end

  # TODO This should probably be checked with Ecto?
  def execute(%User{password_hash: ""}, %ResetPassword{}) do
    Logger.error "An existing user should have a password hash"
    raise "An existing user should have a password hash"
  end
  def execute(_user, %ResetPassword{} = command) do
    Support.convert_similar_structs(command, PasswordReset)
  end

  def apply(%User{} = user, %UserRegistered{} = event) do
    # Simply converting the event to %User{} because there
    # is no state before registering.
    Support.convert_similar_structs(event, User)
  end

  def apply(user, %PasswordReset{password_hash: new_pwhash}) do
    %User{ user | password_hash: new_pwhash }
  end
end
