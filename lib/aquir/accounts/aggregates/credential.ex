defmodule Aquir.Accounts.Aggregates.Credential do
  use Ecto.Schema

  # 2019-01-10_0752 QUESTION TODO
  @doc """
  QUESTION: How to query the state of an aggregate?

  See related 2019-01-10_0725 (and probably others).

  ANSWER: There are  aggregate processes, confirmed by
  the note above.
  """

  alias Aquir.Accounts.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    field :user_id,       :binary_id
    field :type,          :string
    # Why is this not `embeds_many/3`? See NOTE 2019-01-07_1650
    field :payload,       :map
  end

  # 2019-01-10_0544 QUESTION
  @doc """
  + What are correlation and causation IDs?
  + How idiomatic are they in Commanded?
  + How to use them for this project to make it more reliable?

  + Related: How does Commanded utilize event_store?

  From https://stackoverflow.com/questions/53740867/correlation-and-causation-id-in-commanded :
  "The  correlation id  is used  to associate  related
  messages (commands  & events). It  will be set  to a
  random UUID  if you don't provide  it during command
  dispatch."

  Distill that SO thread.
  """

  # 2019-01-10_0604 QUESTION (answered)
  @doc """
  QUESTION: What is the event metadata field supposed to be used for?

  ANSWER:
  https://blog.scooletz.com/2015/08/11/enriching-your-events-with-important-metadata/

  > But what information  can be useful to  store in the
  > metadata, which  info is worth to  store despite the
  > fact that it was not captured in the creation of the
  > model?

  > ### 1. Audit data

  >   + **who?** – simply store the user id of the action invoker
  >   + **when?** – the timestamp of the action and the event(s)
  >   + **why?** – the serialized intent/action of the actor

  > ### 2. Event versioning

  > The  event sourcing  deals  with the  effect of  the
  > actions. An action executed on a state results in an
  > action  according  to  the  current  implementation.
  > Wait.   The   current   implementation?   Yes,   the
  > implementation of  your aggregate can change  and it
  > will either because of bug fixing or introducing new
  > features. **Wouldn’t it be nice if the version, like
  > a  commit  id  (SHA1  for  gitters)  or  a  semantic
  > version could  be stored  with the event  as well?**
  > Imagine that you published a broken version and your
  > business sold 100 tickets  before fixing a bug. It’d
  > be nice to be able  which events were created on the
  > basis  of  the  broken implementation.  Having  this
  > knowledge  you  can easily  compensate  transactions
  > performed by the broken implementation.

  > ### 3. Document implementation details

  > It’s  quite  common  to introduce  canary  releases,
  > feature  toggling  and  A/B tests  for  users.  With
  > automated deployment and  small code enhancement all
  > of the mentioned approaches  are feasible to have on
  > a  project board.  If  you consider  the toggles  or
  > different implementation coexisting in the very same
  > moment, storing the version  only may be not enough.
  > How  about adding  information  which features  were
  > applied for the action? Just  create a simple set of
  > features enabled,  or map feature-status and  add it
  > to the event  as well. Having this  and the command,
  > it’s easy to repeat  the process. Additionally, it’s
  > easy to result in your A/B experiments. Just run the
  > scan for events with A enabled and another for the B
  > ones.

  > ### 4. Optimized combination of 2. and 3.

  > If you think that this  is too much, create a lookup
  > for sets of  versions x features. It’s  not that big
  > and is  repeatable across many users,  hence you can
  > easily optimize  storing the set elsewhere,  under a
  > reference  key.  You  can  serialize  this  map  and
  > calculate SHA1,  put the  values in  a map  (a table
  > will do as well) and  use identifiers to put them in
  > the event.  There’s plenty  of options to  shift the
  > load either to the query (lookups) or to the storage
  > (store everything as named metadata).

  > ## Summing up

  > If  you   create  an  event   sourced  architecture,
  > consider adding the temporal dimension (version) and
  > a  bit of  configuration to  the metadata.  Once you
  > have  it,  it’s  much  easier to  reason  about  the
  > sources of  your events  and introduce  tooling like
  > compensation. There’s  no such  thing like  too much
  > data, is there?
  """

  # 2019-01-10_0633 QUESTION
  @doc """
  QUESTION: How to implement event versioning in Commanded?

  2019-01-10_0604 (event  metadata) is  relevant here,
  but  have to  figure out  the specifics.  See google
  search below as well:

  https://www.google.com/search?q=eventstore+event+versioning&oq=eventstore+event+versioning
  """

  ###########
  # EXECUTE #
  ###########

  def execute(
    %__MODULE__{credential_id: nil},
    %Commands.AddUsernamePasswordCredential{} = command
  ) do
    ACS.convert_struct(command, Events.UsernamePasswordCredentialAdded)
  end

  # TODO: If the password_hash does not exist then the app shouldn't
  #       even compile. Make it a test?
  # def execute(
  #   %__MODULE__{password_hash: ""},
  #   %Commands.ResetPassword{}
  # ) do
  #   Logger.error "An existing user should have a password hash"
  #   raise "An existing user should have a password hash"
  # end

  def execute(_user, %Commands.ResetPassword{} = command) do
    ACS.convert_struct(command, Events.PasswordReset)
  end

  ##########
  ## APPLY #
  ##########

  # TODO Define  debug messages for `c.apply/2`  as well
  # in Commanded. See 2019-01-07_2123 for some context
  def apply(
    %__MODULE__{credential_id: nil},
    %Events.UsernamePasswordCredentialAdded{} = event
  ) do
    ACS.convert_struct(event, __MODULE__)
  end

  def apply(
    user,
    %Events.PasswordReset{
      username:      username,
      password_hash: new_pwhash,
    }
  ) do

    payload = %{
      username:      username,
      password_hash: new_pwhash,
    }

    %__MODULE__{ user | payload: payload }
  end
end
