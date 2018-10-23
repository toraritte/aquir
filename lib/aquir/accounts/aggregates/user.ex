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

  NOTE 2018-10-23_0914 (Dunning-Krueger alert)
  Unique (and  other) constraints  should live  in the
  aggregates and not in arbitrary places. For example,
  the user  email is  checked twice  in `accounts.ex`,
  once in a long-running Agent registering the process
  and  once from  the  User projection,  but a  single
  source of truth is  already available: the aggregate
  instances  (or streams).  (Chose  to  do checks  and
  validations  in `accounts.ex`  because I  don't like
  the current  middleware practice. Read the  notes in
  `router.ex`.)

  Still    need   to    figure   out    the   details,
  but    streams   are    processes   supervised    by
  Commanded.Aggregates.Supervisor. After  restart, its
  list of streams is empty, but issuing a command on a
  specific  stream will  get  it  re-spawned with  the
  correct  state. The  mechanism is  still fuzzy,  but
  added  a  user, stopped  the  server,  and issued  a
  ResetPassword  command after  restart with  success,
  see `:sys.get_state/1` outputs.  Thus this shouldn't
  be a barrier. This way projections can be just dummy
  operations because whatever came in before should be
  clean.

  `consistency:  :strong` also  wouldn't be  needed as
  the User state is being  read back from a projection
  but  from the  aggregate instance  itself. (It  also
  feels  wrong  to  involve a  projection  in  command
  execution. What if the  projections change? But what
  do  I know,  only created  a couple  commands/events
  yet.)

    iex(4)> Aquir.Accounts.register_user(%{"email" => "alvaro@miez.com", "password" => "balabab"})
      #> %Aquir.Accounts.Projections.User{
      #>   __meta__: #Ecto.Schema.Metadata<:loaded, "accounts_users">,
      #>   email: "alvaro@miez.com",
      #>   inserted_at: ~N[2018-10-18 23:52:50.651913],
      #>   password_hash: "$2b$12$EKQm/UHsu4GyXycEkzCet.mrLay7GnayD5Ikhc.zNoe8CWlCyNDSG",
      #>   updated_at: ~N[2018-10-18 23:52:50.651925],
      #>   user_id: "a045a1d0-2461-45ee-8085-261f6fdbb294"
      #> }
    iex(5)>
    BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
          (v)ersion (k)ill (D)b-tables (d)istribution

    $ iex -S mix phx.server
    Erlang/OTP 21 [erts-10.0] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

    iex(3)> :sys.get_state(Commanded.Aggregates.Supervisor)
      #> {:state, {:local, Commanded.Aggregates.Supervisor}, :simple_one_for_one,
      #>  {[Commanded.Aggregates.Aggregate],
      #>   %{
      #>     Commanded.Aggregates.Aggregate => {:child, :undefined,
      #>      Commanded.Aggregates.Aggregate,
      #>      {Commanded.Aggregates.Aggregate, :start_link, []}, :temporary, 5000,
      #>      :worker, [Commanded.Aggregates.Aggregate]}
      #>   }},
      #>  {:sets,
      #>   {:set, 0, 16, 16, 8, 80, 48,
      #>    {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []},
      #>    {{[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []}}}}, 3, 5,
      #>  [], 0, Commanded.Aggregates.Supervisor, []}

    iex(5)> Aquir.Accounts.reset_password(%{"user_id" => "a045a1d0-2461-45ee-8085-261f6fdbb294", "password" => "lofa"})
      #> :ok

    iex(6)> :sys.get_state(Commanded.Aggregates.Supervisor)
      #> {:state, {:local, Commanded.Aggregates.Supervisor}, :simple_one_for_one,
      #>  {[Commanded.Aggregates.Aggregate],
      #>   %{
      #>     Commanded.Aggregates.Aggregate => {:child, :undefined,
      #>      Commanded.Aggregates.Aggregate,
      #>      {Commanded.Aggregates.Aggregate, :start_link, []}, :temporary, 5000,
      #>      :worker, [Commanded.Aggregates.Aggregate]}
      #>   }},
      #>  {:sets,
      #>   {:set, 1, 16, 16, 8, 80, 48,
      #>    {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []},
      #>    {{[], [], [], [], [#PID<0.491.0>], [], [], [], [], [], [], [], [], [], [],
      #>      []}}}}, 3, 5, [], 0, Commanded.Aggregates.Supervisor, []}

    iex(10)> Aquir.Repo.get_by(Aquir.Accounts.Projections.User, email: "alvaro@miez.com")
      #> [debug] QUERY OK source="accounts_users" db=298.2ms decode=0.1ms queue=0.1ms
      #> SELECT a0."user_id", a0."email", a0."password_hash", a0."inserted_at", a0."updated_at" FROM "accounts_users" AS a0 WHERE (a0."email" = $1) ["alvaro@miez.com"]
      #> %Aquir.Accounts.Projections.User{
      #>   __meta__: #Ecto.Schema.Metadata<:loaded, "accounts_users">,
      #>   email: "alvaro@miez.com",
      #>   inserted_at: ~N[2018-10-18 23:52:50.651913],
      #>   password_hash: "$2b$12$dQTXBE4i6RvuGMr9CjBkiuKpQYtAojRAtyi6RWBBAPoU1rM6Sgvwu",
      #>   updated_at: ~N[2018-10-18 23:57:27.187553],
      #>   user_id: "a045a1d0-2461-45ee-8085-261f6fdbb294"
      #> }
  """

  defstruct [
    :user_id,
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

  NOTE 2018-10-19_2208
  What if  new authentication  methods would  be added
  later? I think that the advantage of CQRS/ES in this
  case  is  that  commands  are the  only  input,  and
  their execution's results  are simple events. Adding
  new commands  to the  User aggregate  that register,
  remove, configure etc.  authentication methods for a
  specific User  (e.g., AddAuthenticationMethod) would
  suffice. To decouple it from User, there would be an
  Auth  module with  submodules implementing  the auth
  methods. For example,  Auth.EmailPassword would hold
  all  the  methods  that a  simple  username/password
  login  would  require.  The  auth  method  would  be
  submitted  in   RegisterUser  via  an   atom  (e.g.,
  auth_method: :email_password).
  TODO This is pretty vague, work it out.
  """
  def execute(%User{user_id: nil}, %RegisterUser{} = command) do
    Support.convert_similar_structs(command, UserRegistered)
  end

  ###########
  # EXECUTE #
  ###########
  def execute(%User{password_hash: ""}, %ResetPassword{}) do
    Logger.error "An existing user should have a password hash"
    raise "An existing user should have a password hash"
  end

  def execute(_user, %ResetPassword{} = command) do
    Support.convert_similar_structs(command, PasswordReset)
  end

  #########
  # APPLY #
  #########
  def apply(%User{} = user, %UserRegistered{} = event) do
    # Simply converting the event to %User{} because there
    # is no state before registering.
    Support.convert_similar_structs(event, User)
  end

  def apply(user, %PasswordReset{password_hash: new_pwhash}) do
    %User{ user | password_hash: new_pwhash }
  end
end
