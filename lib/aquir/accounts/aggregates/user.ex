defmodule Aquir.Accounts.Aggregates.User do
  require Logger
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :user_id, :binary_id
    field :name, :string
    field :email, :string
    # TODO see the papers for more

    # See NOTE 2019-01-06_1938 on the missing `embeds_many/3`
  end

  alias Aquir.Accounts.{
    Commands,
    Events,
  }
  alias Aquir.Commanded

  ###########
  # EXECUTE #
  ###########

  # TODO 2019-01-07_2123 QUESTION
  # Follow along  with  IEx.pry when  `execute/2`
  # and  `apply/2` functions  are invoked.  I don't  get
  # the  necessity  of  the  `user_id:  nil`  match  for
  # example  or  whether  in  the  `apply`  below  where
  # the  `UserRegistered` event  is handled,  should the
  # `:user_id` be matched  that is not `nil`  (or with a
  # guard for UUID), etc.
  #
  # See "Building Conduit", page 28 before and after the
  # example again.
  #
  # HOW DOES AN AGGREGATE KNOW THE RIGHT STREAM ID?
  # (That is, `stream_uuid`.)
  #
  # One  possible answer:  the first  key in  each event
  # struct... At least, the  2 events corroborates this:
  # UserRegistered  starts with  :user_id, PasswordReset
  # with :email.
  #
  # ANSWER 2019-01-09_0643
  # OR, the  idiot I am,  one should just look  into the
  # router  (`Aquir.Commanded.Router`) and  look at  the
  # dispatches: each one  ends with `identity:` followed
  # by the preferred key.
  #
  # aquir_eventstore_dev=# SELECT stream_id, stream_events.event_id, event_type, causation_id, correlation_id, convert_from(data,'UTF8'), convert_from(metadata,'UTF8'), created_at FROM events, stream_events WHERE events.event_id = stream_events.event_id and stream_id =

  def execute(
    %__MODULE__{user_id: nil} = user,
    %Commands.RegisterUser{} = command
  ) do
    IO.puts("\n\n")
    IO.inspect(user)
    IO.puts("\n\n")
    Commanded.Support.convert_struct(command, Events.UserRegistered)
  end

  #########
  # APPLY #
  #########

  def apply(%__MODULE__{} = user, %Events.UserRegistered{} = event) do
    IO.puts("\n\n")
    IO.inspect(user)
    IO.puts("\n\n")
    # Simply converting the event to %User{} because there
    # is no state before registering.
    Commanded.Support.convert_struct(event, __MODULE__)
  end
end
