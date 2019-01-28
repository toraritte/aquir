defmodule Aquir.Accounts.Read.Projector do
  use Commanded.Projections.Ecto,
    name: "Aquir.Accounts",
    repo: Aquir.Repo,
    consistency: :strong

  # 2019-01-16_0506 TODO QUESTION (Get to the bottom of :consistency settings)
  @doc """
  Does  it  make  sense   to  talk  about  consistency
  settings per event?

  https://github.com/commanded/commanded/blob/master/guides/Commands.md#command-dispatch-consistency-guarantee

  > Provide  an  explicit  list  of  event  handler  and
  > process manager modules (or their configured names),
  > containing  only   those  handlers  you'd   like  to
  > wait  for. No  other  handlers will  be awaited  on,
  > regardless  of  their   own  configured  consistency
  > setting.

  > ```elixir
  > :ok = BankRouter.dispatch(command, consistency: [ExampleHandler, AnotherHandler])
  > :ok = BankRouter.dispatch(command, consistency: ["ExampleHandler", "AnotherHandler"])
  > ```
  > Note you  cannot opt-in to strong  consistency for a
  > handler  that  has  been  configured  as  eventually
  > consistent.
  """

  # 2018-10-23_2154 QUESTION
  @doc """
  Where is `:consistency` above defined? Commanded.Projections.Ecto
  has  one file basically (ecto.ex) and it's not in there.
  """

  # 2019-01-11_0757 NOTE (Projectors.User -> Accounts.Projector)
  @doc """
  Premise
  =======

  Haven't  found  examples for  defining  associations
  among  projections  in  _Building Conduit_,  only  a
  warning  and  an obscure  (at  least  it feels  like
  that  right now) example on page  106:

  + the warning:

    Projectors work  independently therefore  the tables
    owned by  a projector  shouldn't query the  table of
    another as they  may not be updated  yet, BUT events
    in  a   projector  are  handled  in   order.

    Quote: "**individual projectors must be  responsible
    for populating all data they require.**"

  + the example:

  It  describes   how  to  reference  an   author  for
  a   published   article.   First,   it   takes   the
  `AuthorCreated` event, saves into its "blog_authors"
  table  saving the  `:user_uuid` that  references the
  user in the Accounts context.

  That is, the relationship between
  Accounts.(Aggregates.)User and Blog.(Aggregates.)Author
  is either  **one-to-one** or  **one-to-many**. Right
  now I don't  see a way to know it  for sure but this
  fluidity may be an upside

  It is hard to see the relationships though and

    ISN'T THE WHOLE POINT FOR PROJECTIONS THAT
            THEY CAN TAKE ANY FORM?

  If  one wants  do  design a  specific database  with
  them,  they  should be  able  to.  Or if  one  wants
  a   graphic  database   with  completely   different
  semantics, so be it. Or project selected events into
  a drawing. Whatever.

  QUESTIONs raised:
  + 2019-01-11_0819

  PROPOSAL
  ========

  The gist of the PREMISE is that in "Building Conduit"

  + couldn't  find  any   associations  or  migrations
    suggesting relationships between tables and

  + every projector corresponds  to an aggregate
    (`User` aggregate `User` projector etc.)

  What if the projector handles wider range of events,
  for example for an entire context? Or for an entire
  app?

  Possible corollary: "fat" projectors

  --------------------------------------------------

  UPDATE: 2019-01-14_1038 (Confused CQRS read model with standard projections)
  """

  #  2019-01-11_0819 QUESTION
  @doc """
  QUESTION for 2018-10-23_2154:
  Why not query the  state of the aggregate processes?
  The same  lag applies to  them so they may  not hold
  the most up to date information?
  """

  alias Aquir.Accounts.Read
  alias Read.Schemas, as: RS

  alias Aquir.Accounts.Events
  alias Aquir.Commanded.Support, as: ACS

  @doc """
  The  UserRegistered event  and the  Read.Schemas.User
  struct hold the same keys, hence the conversion, and
  Multi.insert/4  takes  data as  well  in  lieu of  a
  changeset. (Which  is unnecessary because  the event
  is  generated from  the  a command  that is  already
  validated using changesets.)
  """
  project %Events.UserRegistered{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :add_user,
        ACS.convert_struct(event, RS.User)
      )
    end

  project %Events.UsernamePasswordCredentialAdded{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :add_user_credential,
        %RS.Credential{
          credential_id: event.credential_id,
          user_id:       event.user_id,
          type:          event.type,
          username:      event.payload.username,
          password_hash: event.payload.password_hash,
        }
      )
    end

  # TODO QUESTION 2018-10-19_2344
  @doc """
  The state of the User  aggregate is fetched from the
  User  projection in  the  database,  but that  state
  should  also be  available  in  the stream  process.
  Aggregate instances (i.e.,  streams) are implemented
  as  GenServers,  therefore,  unless the  system  has
  been restarted/crashed before,  this state should be
  available.

  If the Phoenix server  has been restarted or crashed
  before the Commanded.Aggregates.Supervisor will show
  no spawned process.

  + How  and  when  will   get  the  stream  processes
    respawned  or on  what  condition  after a  system
    restart?

  + Will their events  get re-applyed automatically on
    such  respawn or  do I  need  to bring  back to  a
    consistent state manually re-applying the events?
  """
  project %Events.PasswordReset{} = event,
    _metadata,
    fn(multi) ->
      # No need to check whether credential  exists  because
      # it would have already been catched  in  the  context
      # (`Accounts.reset_password/1`)

      # TODO 2019-01-15_1255 (Why query the DB multiple times?)
      credential = Read.get(RS.Credential, :username, event.username)

      credential
        |> Ecto.Changeset.change(password_hash: event.password_hash)
        |> (&Ecto.Multi.update(multi, :reset_password, &1)).()
    end
end
# Aquir.Accounts.register_user(%{"email" => "alvaro@miez.com",  "new_password" => "balabab"})
# Aquir.Accounts.reset_password(%{"email" => "alvaro@miez.com", "new_password" => "mas"})
