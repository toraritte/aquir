# Aquir

## 0 Notes on using `Ecto.Schema` in this project

`Ecto.Schema` is used for validating commands and for projections. [This Stack Overflow question](https://stackoverflow.com/questions/52799805) documents the difference between `schema/2` and `embedded_schema/1`, but as soon as Ecto 3 is out, it will be in the main documentation as well.

### 0.1 Read model projections (i.e., migrations and corresponding Ecto.Schema)

#### 0.1.1 Migrations

```elixir
    # (1) Do not generate primary key on table creation
    create table(:accounts_users, primary_key: false) do
      # (2) Do make the uuid field the primary key
      add :uuid, :uuid, primary_key: true
```

(1) and (2) are both needed because the events (e.g., %UserRegistered{}) already contain the UUID (usually taken care of in the command modules, such as RegisterUser). See the [Ecto.Migration](https://hexdocs.pm/ecto/Ecto.Migration.html).{[table/2](https://hexdocs.pm/ecto/Ecto.Migration.html#table/2) and [add/3](https://hexdocs.pm/ecto/Ecto.Migration.html#add/3)} docs.

[`Ecto.Migration.add/3`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#add/3) explains the `:uuid` atom: "_To sum up, the column type may be either an Ecto primitive type, which is normalized in cases where the database does not understand it, such as :string or :binary, or **a database type which is passed as-is**._"

**Note to self**: make migrations easier to distinguish by adding "projection" at the end of their names if it is related to one.

#### 0.1.2 Schemas

```elixir
  @primary_key {:command_key, Ecto.UUID, autogenerate: false}
  #                   |           |                      |
  #                   V           |                      |
  #   e.g., for RegisterUser it   |                      |
  #         is :user_uuid         V                      |
  #                           Using Ecto.UUID.generate() to make
  #                           UUIDs, but for other use cases the
  #                           docs recommended :binary_id would
  #                           probably be more suitable. |
  #                                                      |
  #                                                      V
```

According to the [Ecto.Schema docs](https://hexdocs.pm/ecto/Ecto.Schema.html) "_by default, a schema will automatically generate a primary key which is named id and of type :integer_", but Ecto.Schema is only used here for validation purposes, hence the `false` at the end. Use the [`__schema__`](https://hexdocs.pm/ecto/Ecto.Schema.html#module-reflection) function to introspect the fields at runtime.

```text
iex(2)> alias Aquir.Accounts.Projections.User
iex(3)> User.__schema__(:primary_key)
[:user_id]

iex(10)> User.__schema__(:fields)
[:user_id, :email, :password_hash, :inserted_at, :updated_at]
```

The argument is the same as for migrations above. See [Ecto.Schema docs](https://hexdocs.pm/ecto/Ecto.Schema.html)' ["Primary Keys" section](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primary-keys).

### 0.2 CQRS command schemas (commands and events)

```elixir
@primary_key false
embedded_schema do
  field :user_id,       :binary_id
  field :email,         :string
  field :password,      :string, virtual: true
  field :password_hash, :string, default: ""
end
```

#### 0.2.1 Why the use of `embedded_schema/1` (in commands for example)?

It  results   in  a   `struct`  but  types   can  be
specified  (i.e.,  documented) and  `Ecto.Changeset`
becomes  available  to   do  data  validation  (with
other   `Ecto`   tools   in   general).   See   also
https://stackoverflow.com/questions/52799805.

#### 0.2.2 No primary keys for event and command schemas

Primary  key is  discarded because  `Ecto.Schema` is
only  used  for  data  validation  in  commands  and
events. Projections reflect the  current state of an
aggregate, and  their schemas  do use  primary keys.
Projectors will cast events into their final form.

The current flow:
```text
Command schema -> Event struct -> Projector (Event struct -> Projection schema)
                                      |
                                      V
                                  (as in read model
                                   projector)

Legend: `->` - simple conversion
```

#### 0.2.3 Use of `:virtual` fields

Adding the `virtual` option to the `:password` field
has no significance; it only serves as a reminder to
myself  that  it  would  not  be  persisted  in  the
projection. The  changeset will  simply swap  it out
with a  hashed version (`:password_hash`).  See also
the `Read.Schema.User` schema, it isn't even listed.

#### 0.2.4 `:binary_id` vs `Ecto.UUID`

`:binary_id`    vs   `Ecto.UUID`    can   be    used
interchangeably in **schemas**  but using the former
as it  more general. The `user_id`  is generated via
`Ecto.UUID` anyway.

https://hexdocs.pm/ecto/Ecto.Schema.html#module-primary-keys

### 0.3 Resetting both the Ecto projections, and the EventStore

```
$ mix do ecto.drop, ecto.create, ecto.migrate
$ mix do event_store.drop, event_store.create, event_store.init
```

To run them all at once,  just put a `;` between the
commands.

## 1 How to start this project on your machine (WIP)

See [`./doc/postgresql_commands_dump.txt`](./doc/postgresql_commands_dump.txt) for the specific Postgres commands used (i.e., to get on the console, start the server etc.). Had it documented in another project because I have to re-learn the basics every time when setting up postgres from scratch, but couldn't find the repo...

Relevant Stackoverflow thread: [PostgreSQL's `initdb` fails with “invalid locale settings; check LANG and LC_environment variables”](https://stackoverflow.com/questions/50746147/postgresqls-initdb-fails-with-invalid-locale-settings-check-lang-and-lc-e)

### The boilerplate generated with `mix new`:
To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## 2 PostgreSQL related

```text
# Start the server
$ sudo -u postgres $(which pg_ctl) -D /usr/local/pgsql/data -l /usr/local/pgsql/logfile start

# Get into the `psql` console
$ sudo -u postgres $(which psql)
```

This project uses `commanded/eventstore` that saves events into a PostgreSQL database (into `aquir_eventstore_dev` database), and for simplicity's sake, this where the state store is set up to persist projections (into `aquir_statestore_dev` database). See `./config/dev.exs`. Usually have two terminal windows open for both databases.

```text
Help:                                    \h
                                         \?

List databases:                          \l

Connect to database:                     \c <database>

Toggle expanded output:                  \x
(Helpful for  small screens
to display a wide table.)

Toggle pager (more|less) output:         \pset pager
(Useful one wants to keep a
long  table  output on  the
screen for example.)

List tables in a database:               \d
                                         \d+

Describe table:                          \d <table_name>

List a specific table in its entirety:   TABLE <table_name>;
(See `\h table`, it is under SELECT.)
```

An example:
```text

aquir_eventstore_dev=# \l
                                       List of databases
         Name         |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges

----------------------+----------+----------+-------------+-------------+--------------------
---
 app_env_test_dev     | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_dev            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_eventstore_dev | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_statestore_dev | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_test           | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 postgres             | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres
  +
                      |          |          |             |             | postgres=CTc/postgr
es
 template1            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres
  +
                      |          |          |             |             | postgres=CTc/postgr
es
 timesheets_dev       | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
(9 rows)

aquir_eventstore_dev=#
aquir_eventstore_dev=#
aquir_eventstore_dev=# \l
                                       List of databases
         Name         |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
----------------------+----------+----------+-------------+-------------+-----------------------
 app_env_test_dev     | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_dev            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_eventstore_dev | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_statestore_dev | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 aquir_test           | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 postgres             | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                      |          |          |             |             | postgres=CTc/postgres
 template1            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                      |          |          |             |             | postgres=CTc/postgres
 timesheets_dev       | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
(9 rows)

aquir_eventstore_dev=# \c aquir_eventstore_dev
You are now connected to database "aquir_eventstore_dev" as user "postgres".
aquir_eventstore_dev=# \d
                        List of relations
 Schema |               Name                |   Type   |  Owner
--------+-----------------------------------+----------+----------
 public | events                            | table    | postgres
 public | schema_migrations                 | table    | postgres
 public | snapshots                         | table    | postgres
 public | stream_events                     | table    | postgres
 public | streams                           | table    | postgres
 public | streams_stream_id_seq             | sequence | postgres
 public | subscriptions                     | table    | postgres
 public | subscriptions_subscription_id_seq | sequence | postgres
(8 rows)

aquir_eventstore_dev=# \x
Expanded display is on.
aquir_eventstore_dev=# table events;
-[ RECORD 1 ]--+--------------------------------------------
event_id       | ae68efba-a370-4e72-87da-f506dd58c347
event_type     | Elixir.Aquir.Accounts.Events.UserRegistered
causation_id   | 5df3c2cb-3ef2-406e-b82d-39aa581646ba
correlation_id | e011ede8-4676-4b2b-83c9-c8d18e9b49b1
data           | \x7b22757365725f6964223a226165663361(...)
metadata       | \x7b7d
created_at     | 2018-10-24 05:36:17.60817
-[ RECORD 2 ]--+-------------------------------------------
event_id       | d3969b25-015b-4267-a6ed-bc36f78b4b0e
event_type     | Elixir.Aquir.Accounts.Events.PasswordReset
causation_id   | 0c136a47-a971-4bb6-a28d-33a5ff1e0864
correlation_id | 325d4470-b285-4e8a-b65b-594d10f59d7a
data           | \x7b2270617373776f72645f68617368223a(...)
metadata       | \x7b7d
created_at     | 2018-10-24 05:36:46.740172
```


### 2.1 Convert `bytea` to text in the `events` table output

Using `TABLE events` will show the `data` and `metadata` in [`bytea` Hex format`](https://www.postgresql.org/docs/current/datatype-binary.html), which is the default for `commanded/eventstore`. (See [Getting Started](https://github.com/commanded/eventstore/blob/master/guides/Getting%20Started.md#event-data-and-metadata-data-type).)

```text
aquir_eventstore_dev=# \d events
                                       Table "public.events"
     Column     |            Type             | Collation | Nullable |           Default
----------------+-----------------------------+-----------+----------+------------------------------
 event_id       | uuid                        |           | not null |
 event_type     | text                        |           | not null |
 causation_id   | uuid                        |           |          |
 correlation_id | uuid                        |           |          |
 data           | bytea                       |           | not null |
 metadata       | bytea                       |           |          |
 created_at     | timestamp without time zone |           | not null | timezone('utc'::text, now())
Indexes:
    "events_pkey" PRIMARY KEY, btree (event_id)
Referenced by:
    TABLE "stream_events" CONSTRAINT "stream_events_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(event_id)
Rules:
    no_delete_events AS
    ON DELETE TO events DO INSTEAD NOTHING
    no_update_events AS
    ON UPDATE TO events DO INSTEAD NOTHING
```

Using `convert_from(string bytea, src_encoding name)` function:
```sql
SELECT event_id,
       event_type,
       causation_id,
       correlation_id,
       convert_from(data, 'UTF8'),
       convert_from(metadata,'UTF8'),
       created_at
FROM events;
```

In practice:
```text
aquir_eventstore_dev=# select event_id, event_type, causation_id, correlation_id, convert_from(data, 'UTF8'), convert_from(metadata,'UTF8'), created_at from events;
-[ RECORD 1 ]--+------------------------------------------------------------------------------------------------------------------------------------------------------------
event_id       | ae68efba-a370-4e72-87da-f506dd58c347
event_type     | Elixir.Aquir.Accounts.Events.UserRegistered
causation_id   | 5df3c2cb-3ef2-406e-b82d-39aa581646ba
correlation_id | e011ede8-4676-4b2b-83c9-c8d18e9b49b1
convert_from   | {"user_id":"aef3a738-af21-4165-94ef-dfb18abb00bd","password_hash":"$2b$12$rh/cpbZkpytOZ8iIuNUs7uvPPI.sZsB338Q8ujzssAc97n4ii16ie","email":"alvaro@miez.com"}
convert_from   | {}
created_at     | 2018-10-24 05:36:17.60817
-[ RECORD 2 ]--+------------------------------------------------------------------------------------------------------------------------------------------------------------
event_id       | d3969b25-015b-4267-a6ed-bc36f78b4b0e
event_type     | Elixir.Aquir.Accounts.Events.PasswordReset
causation_id   | 0c136a47-a971-4bb6-a28d-33a5ff1e0864
correlation_id | 325d4470-b285-4e8a-b65b-594d10f59d7a
convert_from   | {"password_hash":"$2b$12$IUUhwJ2hiQhZruNA3gTUa.Bvsst/sZyDl54OAt65jx9XF2aOdI5wC","email":"alvaro@miez.com"}
convert_from   | {}
created_at     | 2018-10-24 05:36:46.740172
```

## NOTEs, long/obscure TODOs, QUESTIONs

### 2018-10-11_2312 NOTE TODO (Commanded.Middleware)

2018-10-11_2312
2018-10-23_0914
2018-10-19_2246
2018-10-18_0004

RegisterUser   command  validation   is  done   here
(i.e.,  in  the   `Accounts`  context),  instead  of
Aquir.Commanded.Router  using  Commanded.Middleware,
(as   described   in  Building   Conduit),   because
RegisterUser will  only be called from  the Accounts
context.  After  all,  its  whole  point  is  to  be
an  abstraction  boundary   for  dealing  with  user
management).

If the command would need  to be called from another
context,  then the  middleware  approach would  make
more  sense.  But  then  again,  shouldn't  contexts
only interact  with each other through  their public
functions?  We'll see  whether I  am oversimplifying
things.

Used  Ecto.Changeset  instead  of  Vex,  which  also
resulted   in    omitting   ExConstructor,   because
generating a changeset from  the incoming raw params
will result  in "clean" maps (i.e.,  the string keys
become  atoms)  thus  Kernel.struct/2  can  be  used
to  instantiate  the  RegisterUser struct  with  the
changes.

See https://stackoverflow.com/questions/30927635/in-elixir-how-do-you-initialize-a-struct-with-a-map-variable

CAVEAT:  Using the  changeset  approach requires  to
check  the  results   BEFORE  dispatching  the  CQRS
command! Otherwise the process will crash after many
retries of a faulty event.

### 2018-10-14_2339 NOTE QUESTION

Instill these slides: https://www.slideshare.net/andrewhao/building-beautiful-systems-with-phoenix-contexts-and-domaindriven-design

So  if credentials  would need  to be  added at  one
point  (to support  different auth  mechanisms, e.g.
OAuth), then  this would  probably be  the aggregate
root (i.e.,  aggregates/user.ex) and  the supporting
objects would go to the "user" directory:

```text
aggregates/
|- user/
|   |- credential.ex
|   |- etc.ex
|- user.ex
```

It's still fuzzy how the schemas would look like, but
the  domain is  complex  enough that  there will  be
plenty of opportunity to figure it out.

### 2018-10-14_2348 NOTE (User aggregate)

An  aggregate   instance  (i.e.,  a  stream)   is  a
gen_server,  and the  first argument  to `execute/2`
and `apply/2`  are the state  of the process.  It is
still unclear  how these  functions get  called, but
this makes the most sense at the moment.

### 2018-10-15_2316 NOTE (User aggregate)

The  `execute/2`  clauses  are  simple,  because  by
the  time the  command  gets here,  it already  went
through validation  via changesets in  context (such
as `accounts.ex`).

### 2018-10-18_0004 NOTE TODO (Commanded.Middleware)

2018-10-11_2312
2018-10-23_0914
2018-10-19_2246
2018-10-18_0004

Keeping   command   validation    in   the   context
(i.e.,  `Account.ex`)  as  I  am  not  fond  of  the
Commanded.Middleware   implementation.    See   note
"2018-10-19_2246" in Aquir.Commanded.Router.

### 2018-10-19_2208 NOTE TODO(?) (User aggregate)

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
`auth_method: :email_password`).

TODO This is pretty vague, work it out.

### 2018-10-19_2246 NOTE TODO (Commanded.Middleware)

2018-10-11_2312
2018-10-23_0914
2018-10-19_2246
2018-10-18_0004

Commanded.Middleware is  currently implemented  as a
behaviour with before  and after dispatch callbacks,
and every middleware in a  router is called for each
command.  Pattern match  is needed  in the  specific
middlewares, but this  way it is hard  to know which
middleware is used for which command unless one goes
through every  middleware. Also,  there may  be that
one  middleware  is  needed   only  for  one  single
command.

Use something  similar to `pipeline/2` and
`pipe_through/1` in  Phoenix. It won't be  simple as
there are  default middleware  implementations added
in Commanded.Commands.Router.

### 2018-10-23_0914 NOTE TODO(?) (Commanded.Middleware also?)

Related notes:
+ 2019-01-04_1152
+ 2019-01-09_1200
+ 2018-12-31_1019
+ 2018-10-23_0914

(Regarding Commanded.Middleware:

2018-10-11_2312
2018-10-23_0914
2018-10-19_2246
2018-10-18_0004               )

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
correct state. (^1) The mechanism is still fuzzy, but
added  a  user, stopped  the  server,  and issued  a
ResetPassword  command after  restart with  success,
see `:sys.get_state/1` outputs.  Thus this shouldn't
be a barrier. This way projections can be just dummy
operations because whatever came in before should be
clean.

(^1) The state is correct because  it is taken from the
projection itself and NOT from the aggregate...

`consistency:  :strong` also  wouldn't be  needed as
the User state is being  read back from a projection
but  from the  aggregate instance  itself. (It  also
feels  wrong  to  involve a  projection  in  command
execution. What if the  projections change? But what
do  I know,  only created  a couple  commands/events
yet.)

```text
iex(1)> Aquir.Accounts.register_user(%{"email" => "alvaro@miez.com", "password" => "balabab"})
> (...)
%Aquir.Accounts.Projections.User{
  __meta__: #Ecto.Schema.Metadata<:loaded, "accounts_users">,
  email: "alvaro@miez.com",
  inserted_at: ~N[2018-10-24 05:36:17.848485],
  password_hash: "$2b$12$rh/cpbZkpytOZ8iIuNUs7uvPPI.sZsB338Q8ujzssAc97n4ii16ie",
  updated_at: ~N[2018-10-24 05:36:17.848501],
  user_id: "aef3a738-af21-4165-94ef-dfb18abb00bd"
}

iex(2)> Supervisor.which_children(Commanded.Aggregates.Supervisor)
[{:undefined, #PID<0.486.0>, :worker, [Commanded.Aggregates.Aggregate]}]

iex(3)>
BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
        (v)ersion (k)ill (D)b-tables (d)istribution
$ iex -S mix phx.server
Erlang/OTP 21 [erts-10.0] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

iex(1)> Supervisor.which_children(Commanded.Aggregates.Supervisor)
> []

iex(2)> Aquir.Accounts.reset_password(%{"email" => "alvaro@miez.com", "new_password" => "mas"})
> :ok

iex(3)> Aquir.Accounts.Projections.User.get_user_by_email("alvaro@miez.com")
%Aquir.Accounts.Projections.User{
  __meta__: #Ecto.Schema.Metadata<:loaded, "accounts_users">,
  email: "alvaro@miez.com",
  inserted_at: ~N[2018-10-24 05:36:17.848485],
  password_hash: "$2b$12$IUUhwJ2hiQhZruNA3gTUa.Bvsst/sZyDl54OAt65jx9XF2aOdI5wC",
  updated_at: ~N[2018-10-24 05:36:47.000317],
  user_id: "aef3a738-af21-4165-94ef-dfb18abb00bd"
}

iex(4)> Supervisor.which_children(Commanded.Aggregates.Supervisor)
[{:undefined, #PID<0.475.0>, :worker, [Commanded.Aggregates.Aggregate]}]

iex(5)> :sys.get_state(Commanded.Aggregates.Supervisor)
{:state, {:local, Commanded.Aggregates.Supervisor}, :simple_one_for_one,
 {[Commanded.Aggregates.Aggregate],
  %{
    Commanded.Aggregates.Aggregate => {:child, :undefined,
     Commanded.Aggregates.Aggregate,
     {Commanded.Aggregates.Aggregate, :start_link, []}, :temporary, 5000,
     :worker, [Commanded.Aggregates.Aggregate]}
  }},
 {:sets,
  {:set, 1, 16, 16, 8, 80, 48,
   {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []},
   {{[], [], [], [], [#PID<0.475.0>], [], [], [], [], [], [], [], [], [], [],
     []}}}}, 3, 5, [], 0, Commanded.Aggregates.Supervisor, []}
```

### 2018-12-31_1019 TODO(?) (duplicate?)

Related notes:
+ 2019-01-04_1152
+ 2019-01-09_1200
+ 2018-12-31_1019
+ 2018-10-23_0914

There is a simmetry between commands and events, and
duplicated  code with  that it  seems. The  commands
are changesets  that produce  almost the  same event
structs, and  aggregate `apply`s and  `execute`s are
basically just  conversions from  one struct  to the
other. (See `Aquir.Accounts.Aggregates.User`.)

Projections  mirror the  commands even  more so,  as
they are changesets themselves  as well, as they are
basically commands persisted into  the DB as current
state. (That is, commands -> events -> projections.)

But of course, I just realized that a projection can
combine many more command fields.

( Update on 2019-01-14_0724: )

+ Aquir.Accounts.Aggregates.User
+ Aquir.Accounts.Commands.RegisterUser
+ Aquir.Accounts.Events.UserRegistered

These structs are (almost) identical and they define
the same  structure multiple  times; the  only thing
that differs is the  struct's (i.e., module's) name.
In Haskell(-like)  languages a record would  just be
tagged and  re-packed whenever needed.  For example,
data  validation is  done  on `RegisterUser`  before
conversion  to `UserRegistered`,  but that  could be
part of the re-packing process.

Take  a  look  at   Witchcraft  and  Algae.  (Purerl
would probably  be a  much bigger leap,  leaving the
entire Elixir  ecosystem behind.  Or maybe  not? The
underlying system is Erlang for both anyway.

### 2019-01-04_1148 NOTE TODO(?)

A new  Credential aggregate would be  in many-to-one
association to the User aggregate, so trying to find
ways to make that happen.

Would this be more useful for projections?

Resources:
+ examples taken from https://github.com/elixir-ecto/ecto/issues/1375
+ some list of ecto issues (https://elixirforum.com/t/how-to-handle-association-with-embedded-schema/14723/5)
+ https://stackoverflow.com/questions/40309269/ecto-updating-nested-embed
+ https://stackoverflow.com/questions/44744859/ecto-handling-deeply-nested-associations-in-embedded-schema
+ https://www.google.com/search?q=elixir+ecto+embeds&oq=elixir+ecto+embeds
+ https://robots.thoughtbot.com/embedding-elixir-structs-in-ecto-models
+ https://www.google.com/search?q=elixir+embeds+inside+embeds&oq=elixir+embeds+inside+embeds
+ http://blog.plataformatec.com.br/2015/08/working-with-ecto-associations-and-embeds/
+ https://pragprog.com/book/wmecto/programming-ecto

```elixir
defmodule NewOrderCommand do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, Ecto.UUID

    embeds_one :address, Address do
      field :street, :string
      field :country, :string
    end

    embeds_many :items, Item do
      field :item_id, Ecto.UUID
      field :quantity, :integer
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:user_id])
    |> cast_embed(:address, with: &address_changeset/2)
    |> cast_embed(:items, with: &item_changeset/2)
    |> validate_required([:user_id, :address, :items])
  end

  defp address_changeset(struct, params) do
    struct
    |> cast(params, [:street, :city])
    |> validate_required([:street, :city])
  end

  defp item_changeset(struct, params) do
    struct
    |> cast(params, [:item_id, :quantity])
    |> validate_required([:item_id, :quantity])
    |> validate_number(:quantity, min: 0)
  end
end
```

IEx output:
```text
{:module, NewOrderCommand,
<<70, 79, 82, 49, 0, 0, 17, 56, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 2, 105,
0, 0, 0, 58, 22, 69, 108, 105, 120, 105, 114, 46, 78, 101, 119, 79, 114, 100,
101, 114, 67, 111, 109, 109, 97, 110, 100, ...>>, {:item_changeset, 2}}

iex(12)> NewOrderCommand.changeset(%NewOrderCommand{}, %{})
#Ecto.Changeset<
action: nil,
changes: %{},
errors: [
user_id: {"can't be blank", [validation: :required]},
address: {"can't be blank", [validation: :required]}
],
data: #NewOrderCommand<>,
valid?: false
>
```

Also works when the embeds are defined separately:
```elixir
defmodule Address do
  use Ecto.Schema

  embedded_schema do
    field :street, :string
    field :country, :string
  end
end

defmodule Item do
  use Ecto.Schema

  embedded_schema do
    field :item_id, Ecto.UUID
    field :quantity, :integer
  end
end

defmodule NewOrderCommand do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, Ecto.UUID

    embeds_one :address, Address
    embeds_many :items, Item
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:user_id])
    |> cast_embed(:address, with: &address_changeset/2)
    |> cast_embed(:items, with: &item_changeset/2)
    |> validate_required([:user_id, :address, :items])
  end

  defp address_changeset(struct, params) do
    struct
    |> cast(params, [:street, :city])
    |> validate_required([:street, :city])
  end

  defp item_changeset(struct, params) do
    struct
    |> cast(params, [:item_id, :quantity])
    |> validate_required([:item_id, :quantity])
    |> validate_number(:quantity, min: 0)
  end
end
```

IEx output will be the same as for the first version.

### 2019-01-04_1152 NOTE TODO(?) (Aggregate associations/relationships)

Related notes:
+ 2019-01-04_1152
+ 2019-01-09_1200
+ 2018-12-31_1019
+ 2018-10-23_0914

The notion is that the

+ User  aggregate  holds  the  user  personal  details
(user_id,  email, name,  etc, TODO:  make a  Profile
aggregate?)

+ Credential   aggregate   stores  alternative   login
methods (e.g., social login IDs)

To put it in a  very simplistic way, an aggregate is
something that has to have  an ID. Credentials for a
specific user  fits this description. It  also means
that the relationship between User and Credential is
one-to-many, i.e.  `User -<  Credential`. Aggregates
are indepent from each  other, therefore there is no
need to  explicitly declare this  dependency between
them; the projections are going to reflect this fact
(e.g., with  associations), and it is  the context's
job  (`accounts.ex`  in  this  case)  to  coordinate
between aggregates and enforce business rules (i.e.,
invoke  the commands'  changesets, checking  whether
user already registered etc.).

With that said, it would  still be useful to have it
reflected  in the  aggregates' state,  even if  only
for  documentation's sake.  `embeds_many` in  `User`
aggregate and `:for_user_id` in Credential aggregate
reflects this relationship clearly.

### 2019-01-06_1938 NOTE (Why no `embeds_many/3` in `User` aggregate?)

Removed   `embeds_many/3`   from  `User`   aggregate
because it would couple the aggregates, complicating
the code,  and it is unnecessary  because aggregates
should  be  independent.   Context  will  coordinate
between  them   (e.g.,  when  registering   a  user,
pass  the `user_id`  of  a new  `User` aggregate  to
the  `Credential`  commands), and  projections  will
explicitly show the relationship(s).

UPDATE 2019-01-16_0804
Also unnecessary because this is the "write" side of
CQRS, only used for  command validation on dispatch.
The "read"  side (`Aquir.Accounts.Read.Schemas`) has
the proper association to make more involved queries
(e.g., `has_many/?` in `Schemas.User`).

### 2019-01-07 TODO

Allow event and command definition in aggregates.

Right  now,  command  and   events  are  defined  in
separate  modules, and  most of  time they  have the
exact  same structure.  Make it  possible to  define
them in the aggregate module  AND to simply copy the
aggregates structure  or just add field  that differ
to avoid duplication.

Also, the  mile long  module names  look ridiculous,
yet they do belong in those places.

### 2019-01-07_1650 NOTE

The `Credential` aggregate has  a `:data` field with
the  type  of a  `map`  because  here is  where  the
credential-specific  information goes.  For example,
for  command   `AddUsernamePasswordCredential`  this
data  is  the   username,  password  and  eventually
the  hashed password.  Adding a  social login  would
result  in an  embed with  different fields  (though
`:credential_id`,  `:for_user_id`  and  `:type`  are
shared among other types).

Even if  the fields would  be the same, it  would be
`embeds_one/3`  because  it  is a  template  for  an
aggregate instance  (i.e., it holds the  value for a
single  credential type  and therefore  has an  ID).
This fact is reflected in the name of the aggregates
as well, which are always singular.

### 2019-01-03_1117 TODO

Specify   typespec    for   `imbue_command`.   Won't
be   straightforward  as   `Ecto.Schema`  does   not
automatically  generate   a  type  when   used.  See
discussions on Elixir Forum or in [TypedStruct issue #5](https://github.com/ejpcmac/typed_struct/issues/5).

### 2019-01-05_2314 NOTE (Evolution of `imbue_command`)

I  assumed  that   when  `Ecto.Changeset.cast/4`  is
applied on  a struct,  it won't preserve  the values
already  in  it because  I  didn't  see the  default
`type`  value   for  `AddUsernamePasswordCredential`
or  the  assigned   ID  for  `RegisterUser`  command
in `changes` afterwards. This was stupid.

A reminder to self:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
A  CHANGESET IS  A  STRUCT TO  DEAL WITH  VALIDATION
RESULTS WITHOUT MUTATING THE SCHEMA STRUCT.

A changeset's
+ `changes` holds values that passed validation
+ `data` stores the original struct argument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Therefore to get the updated struct after validation:
`struct(changeset.data, changeset.changes)`

### 2019-01-06_0838 NOTE (Evolution of `imbue_command`)

[Ecto issue #1375](https://github.com/elixir-ecto/ecto/issues/1375)
proposed  allowing  "Inline   embeds"  and  this  is
used in `AddUsernamePasswordCredential` command. The
previous version  of `imbue_command` was not  fit to
handle  it as  changesets have  been nested  in each
other. To elaborate:

```elixir
# Previous version of `imbue_command`
def imbue_command(%command{} = command_struct, attrs) do

  changeset = command.changeset(command_struct, attrs)

  case changeset.valid? do
    true ->
      command_with_params = struct(changeset.data, changeset.changes)
      {:ok, command_with_params}
    false ->
      {:error, changeset}
  end
end
```

`AddUsernamePasswordCredential` changeset would
produce the following struct:

```text
iex(57)> c =  AddUsernamePasswordCredential.changeset(
...(57)>        %AddUsernamePasswordCredential{},
...(57)>        %{ for_user_id: Ecto.UUID.generate(),
...(57)>           credential:  %{username: "lofa", password: "balabab"}
...(57)>         }
...(57)>      )
#Ecto.Changeset<                   # changeset-1
  action: nil,
  changes: %{
    credential: #Ecto.Changeset<   # changeset-2
      action: :insert,
      changes: %{
        password_hash: "$2b$12$QyPBut6OKdJUmNqL/JPMS.0c95Akdor/qt9n/bIT5JkYB0j0i6m1C",
        username: "lofa"
      },
      errors: [],
      data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Credential<>,
      valid?: true
    >,
    for_user_id: "14d67efd-ee41-4cb2-964e-55ed1baa8e6f"
  },
  errors: [],
  data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential<>,
  valid?: true
>
```

... and  the above  `imbue_command` would  result in
the struct below, note the lingering changeset:

```text
iex(55)> Aquir.Commanded.Support.imbue_command(
...(55)>   %AddUsernamePasswordCredential{},
...(55)>   %{ for_user_id: Ecto.UUID.generate(),
...(55)>    credential: %{username: "lofa", password: "balabab"}
...(55)>   }
...(55)> )
{:ok,
%Aquir.Accounts.Commands.AddUsernamePasswordCredential{
  credential: #Ecto.Changeset<
    action: :insert,
    changes: %{
      password_hash: "$2b$12$LHbgjMaUZrGYAWEKHvqORejl2L/1ENvSViYORap7yOaaEmvVOEa7q",
      username: "lofa"
    },
    errors: [],
    data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Credential<>,
    valid?: true
  >,
  credential_id: "3e9641d3-ce8e-4a80-b1dc-d0a5ca718521",
  for_user_id: "8ed18f96-32f4-45ba-8cae-51c3e9a9491e",
  type: "username_password"
}}
```

Issue  #1375 fortunately  also  shows the  solution:
`Ecto.Changeset.apply_changes/1`.    It    basically
recursively applies  `changes` to the `data`  in the
changeset(s).  Checking  for changeset  validity  is
still necessary as it  "[_will return the underlying
data  with changes  regardless if  the changeset  is
valid or not_](https://hexdocs.pm/ecto/Ecto.Changeset.html#apply_changes/1)".

  An example run on the same `AddUsernamePasswordCredential`
  embedded changeset example above (saved to variable `c`):

```elixir
iex(58)> Ecto.Changeset.apply_changes(c)
%Aquir.Accounts.Commands.AddUsernamePasswordCredential{
  credential: %Aquir.Accounts.Commands.AddUsernamePasswordCredential.Credential{
    id: nil,
    password: nil,
    password_hash: "$2b$12$QyPBut6OKdJUmNqL/JPMS.0c95Akdor/qt9n/bIT5JkYB0j0i6m1C",
    username: "lofa"
  },
  credential_id: "35ce3d09-6780-49f4-8c99-e82efb91bbe9",
  for_user_id: "14d67efd-ee41-4cb2-964e-55ed1baa8e6f",
  type: "username_password"
}
```

### 2019-01-06_0838 NOTE (Evolution of `imbue_command`)

A single context function handles multiple commands,
and at the time of this writing, handling validation
sequentially. Context function  arguments would have
to be handled atomically though. A use case:

  `Accounts.register_user/1`  accepts  a  map  with  4
  keys,  2-2 for  each command.  If the  first command
  isn't   valid,  the   entire  function   returns  an
  `{:error,  changeset}`  tuple,  but  the  subsequent
  command is never checked.

It   would  be   prudent   to  let   the  end   user
know   about   all    of   the   errors,   therefore
refactoring  `imbue_command`  to  accept a  list  of
`{command_struct,  attrs_map}`  tuples, and  provide
all errors in  the form of a list  of changesets, or
the imbued commands otherwise.

NOTE Why this output? (i.e., changesets on error, commands otherwise)

Because

+  on  **success**,  the  commands will  be  fed  to
   `Aquir.Commanded.Router` to be dispatched

+ on **failure**,  the context will return  the errors
  as changesets  because all validations are  done via
  Ecto.Changesets.  This  means  that  any  sub-system
  consuming  this output  can  do any  transformations
  they want.

  For example, views and templates can take changesets
  and  then extract  errors if  any. But  what if  the
  front  end  is  moved  from Phoenix  to  a  JS  lib?
  Then  just  extract  the errors  from  the  (nested
  changesets into a map, etc.

### 2019-01-05_2302 NOTE (How to add change to a changeset?)

```elixir
def assign_id(command_changeset, struct_field) do
  case command_changeset.valid? do
    true ->
      uuid = Ecto.UUID.generate()
      Ecto.Changeset.put_change(command_changeset, struct_field, uuid)
    false ->
      command_changeset
  end
end
```

### 2019-01-07_2123 QUESTION

Follow along  with  IEx.pry when  `execute/2`
and  `apply/2` functions  are invoked.  I don't  get
the  necessity  of  the  `user_id:  nil`  match  for
example  or  whether  in  the  `apply`  below  where
the  `UserRegistered` event  is handled,  should the
`:user_id` be matched  that is not `nil`  (or with a
guard for UUID), etc.

See "Building Conduit", page 28 before and after the
example again.

ANSWER

When   dispatching   the   `RegisterUser`   command,
Commanded  will   try  to  find   the  corresponding
aggregate   using   the    `:user_id`   (i.e.,   the
`:identity`  set   by  the  `dispatch/2`   macro  in
`Aquir.Commanded.Router`).

Commanded has great debug  output, so when trying to
register a user (right now at commit 53c9a5f):

```text
iex(1)> Aquir.Accounts.register_user(%{"name" => "d", "email" => "@d"})
[debug] Locating aggregate process for `Aquir.Accounts.Aggregates.User` with UUID "c4c84fa8-5daa-4300-b63c-51d567560fe8"
```

Not in the debug output, but I know that there isn't
any `User`  stream with that  ID, so the  state will
be:

```elixir
%Aquir.Accounts.Aggregates.User{email: nil, name: nil, user_id: nil}
```

Hence  the check  for  `user_id: nil`,  but at  this
point one could simply  just omit this argument with
`_`, but it is always prudent to check.

### 2019-01-07_2127 TODO

Commanded debug messages are  indeed good, but there
doesn't seem to be any defined for `apply/2`.


  # 2019-01-09_0643 QUESTION
  # HOW DOES AN AGGREGATE KNOW THE RIGHT STREAM ID?
  # (That is, `stream_uuid`.)
  #
  # One  possible answer:  the first  key in  each event
  # struct... At least, the  2 events corroborates this:
  # UserRegistered  starts with  :user_id, PasswordReset
  # with :email.
  #
  # ANSWER
  # OR, the  idiot I am,  one should just look  into the
  # router  (`Aquir.Commanded.Router`) and  look at  the
  # dispatches: each one  ends with `identity:` followed
  # by the preferred key.
  #
  # aquir_eventstore_dev=# SELECT stream_id, stream_events.event_id, event_type, causation_id, correlation_id, convert_from(data,'UTF8'), convert_from(metadata,'UTF8'), created_at FROM events, stream_events WHERE events.event_id = stream_events.event_id and stream_id =

SELECT stream_id, stream_events.event_id, event_type, causation_id, correlation_id, convert_from(data,'UTF8'), convert_from(metadata,'UTF8'), created_at, stream_version FROM events, stream_events WHERE events.event_id = stream_events.event_id and stream_id = 6;

### 2019-01-09_1200 TODO (`build_schema` macro)

Related notes:
+ 2019-01-04_1152
+ 2019-01-09_1200
+ 2018-12-31_1019
+ 2018-10-23_0914

Another take on making a `build_schema` macro:

+ allows  copying fields into  the events/commands
  from the aggregate
  => corollary: document  in events/commands which
     aggregate they belong to

+ ID  is autogenerated,  and so  far it  is always
  <aggregate-name>_id

### 2019-01-15_1223 NOTE (Why the `:credential_id`?)

COMMANDS

Aggregate instances  are identified by  their unique
identifier. These  indentities are specified  in the
router (`Aquir.Commanded.Router`)  when commands are
dispatched:

```elixir
dispatch [C.AddUsernamePasswordCredential],
to: A.Credential,
identity: :credential_id
```

If this identity is not  part of all the commands in
the aggregate, the aggregate may  start a new one or
just  fails.  See  2019-01-15_0918 to  change  these
IDs  to `_aid`s  (as  in aggregate  IDs  to be  more
descriptive.

EVENTS

In  the  case  of   `PasswordReset`  event,  the  ID
wouldn't be  strictly necessary, because  the record
could be  looked up  by the  username, but  it never
hurts to  hold this information. Maybe  in metadata?
See 2019-01-15_0918

### 2019-01-15_1255 TODO (Why query the DB multiple times?)

  Any operation that requires to update the read model
  effectively results in two  or more queries. Once in
  the context  (e.g., `Accounts`) and  once projecting
  an update to the read model.

  There is  only a couple events/commands  but keep an
  eye on this trend.

  SOLUTION: Query the aggregate instance process.
            See 2019-01-10_0752

### 2019-01-21_0550 NOTE (`Accounts.register_user/1` and `Unique.claim/1` refactor)

+ Removing `with/1`  because all error  messages are
  needed  to be  collected,  but  `with/1` fails  on
  the first  one and  ignoring any  subsequent ones.
  (See  2019-01-21_0555  QUESTION  for  the  pattern
  description.)

+ Checking   for    claimed   entities    TWICE   in
  `Accounts.register_user/1`:

  when applying  functions to  get all  results, and
  when actually  claiming (i.e.,  registering) these
  entities on  no errors. The rationale  for this is
  that  between  just  checking and  claiming  there
  could  be  another  process doing  the  same  (yay
  distribution).

+ Making `Unique.claim/1`  more complicated  so that
  all registration in a context function can be done
  in  a transaction.  If done  using iteration  on a
  list  of key-value  pairs, it  is possible  that a
  function  is running  in  parallel  with the  same
  arguments,  making one  pair register  and another
  one fail. Then the  context function would have to
  have  a more  complicated checking  mechanism, and
  figure out how to  roll back partial claims, maybe
  even causing oscillations in the other conflicting
  function invocations.  This way, either  all pairs
  fail or  succeed because  the Unique  process will
  execute any requests sequentially.

  For example:

  ```text
    register_user(params1)             register_user(params2)
    | claim(email: "@a") -> :ok        |
    |                                  | claim(email: "@a") -> :error
    |                                  | claim(username: "aa") -> :ok
    | claim(username: "aa") -> :error  |
    ?                                  ?
  ```

### 2019-01-21_0555 QUESTION (Is this Applicative?)

In 2019-01-15_1255 refactor functions are applied in
a list,  and each function is  an `Either` returning
tagged tuples in the form of `{:ok, _}` or `{:error,
_}`.  That   result  list  is  then   filtered,  and
execution only continues when no errors are present,
returning the accumulated errors otherwise.

Remember this  pattern from  the _Haskell  Book_ and
_PureScript  By  Example_  but not  sure  about  the
specifics. Look it up.

(Just  realized that  the  same pattern  is used  in
`Unique.claim/1`,  only  the  tags are  `:free`  and
`:taken`.)

### 2019-01-21_0827 TODO (`with/2`-like macro collecting results with deps)

See 2019-01-21_0550 and 2019-01-21_0555 for context.
See  `Accounts.reset_password/1` especially,  as the
second function call  (`imbue_command/2`) depends on
the first (getting the user credential).

In `Accounts.reset_password/1`, `imbue_command/2` is
called   with  `attrs_with_maybe_fake_credential_id`
that  is generated  depending  whether a  credential
exists  or not.  The  reason is  that if  credential
does  not exist  then `imbue_command`  will fail  as
`PasswordReset` changeset  needs a `:credential_id`.
So,  in  order to  still  allow  checking the  input
attributes, it is being faked; the entire thing will
fail anyway.

### 2019-01-23_0603 NOTE (Why only check for email?)

Because at  the time of this  writing, usernames are
derived  from email  addresses therefore  if one  is
taken then the so is  the other. Also, usernames are
not even part of the form.

### 2019-01-23_0617 NOTE (homogeneous lists)

Homogeneous  lists would  be  nice, or  a guard  for
them.  Another reason  for switching  to purerl  (or
witchcraft?).

### 2019-01-23_0745 NOTE (`Ecto.Changeset.traverse_errors/2` example)

```text
iex(44)> a = Aquir.Accounts.Commands.AddUsernamePasswordCredential.changeset(%Aquir.Acco
unts.Commands.AddUsernamePasswordCredential{}, %{payload: %{}})
#Ecto.Changeset<
  action: nil,
  changes: %{
    payload: #Ecto.Changeset<
      action: :insert,
      changes: %{},
      errors: [
        username: {"can't be blank", [validation: :required]},
        password: {"can't be blank", [validation: :required]}
      ],
      data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Payload<>,
      valid?: false
    >
  },
  errors: [for_user_id: {"can't be blank", [validation: :required]}],
  data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential<>,
  valid?: false
>
iex(45)> Enum.map([a], fn(changeset) -> Ecto.Changeset.traverse_errors(changeset, &(&1)) end)
[
  %{
    for_user_id: [{"can't be blank", [validation: :required]}],
    payload: %{
      password: [{"can't be blank", [validation: :required]}],
      username: [{"can't be blank", [validation: :required]}]
    }
  }
]
```

### 2019-01-23_0800 NOTE (Why not `nil`? Or ...)

Or  check   for  empty  lists  after   flatten?  The
`:errors`  assign should  be  `nil` if  there is  no
errors (or only ones that can be ignored).

The  reason  is that  (at  this  time) the  username
is  derived  from  the  email address,  and  if  the
address  is  invalid,  there would  be  a  changeset
error. If  valid, then  the username  also shouldn't
generate. (Detto for  uniqueness checks for username
and email.)

### 2019-01-19_1434 TODO (Make more descriptive foldtexts)

For example, what is the main tag under the <div>s?
https://stackoverflow.com/questions/5983396/

### 2019-01-18_0000 TODO (email validation) %>

Only using a very broad pattern, because to properly
validate an email address  with regex borders on the
impossible and email confirmation would be necessary
anyway. See this answer in particular:

https://stackoverflow.com/a/202528/1498178

This post shows  a high level, but  helpful, flow on
how  to do  email  verification  securely with  only
built-in Phoenix tools:

https://dockyard.com/blog/2017/09/06/adding-email-verification-flow-with-phoenix

Before I forget:
check out `Ecto.Changeset.validate_confirmation/3`

### 2019-01-23_1150 TODO (tooltip accessibility)

How accessible is the  popup tooltip when validating
the email address?

### 2019-01-18_0503 TODO (multi-round password validation)

Validate password by having  users enter them again.
Or  admins, if  this is  not  going to  be a  public
facing page.

### 2019-01-24_0810 NOTE (Breaking down `UserController.parse_errors/1`)

```elixir
# {:errors, cs_only} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "@a.a", "password" => "lofa"})
# -----------------------------------------

{:errors,
 [
   invalid_changesets: [
     #Ecto.Changeset<
       action: nil,
       changes: %{email: "@a.a", name: "F"},
       errors: [email: {"has invalid format", [validation: :format]}],
       data: #Aquir.Accounts.Commands.RegisterUser<>,
       valid?: false
     >,
     #Ecto.Changeset<
       action: nil,
       changes: %{
         payload: #Ecto.Changeset<
           action: :insert,
           changes: %{password: "lofa"},
           errors: [
             password: {"should be at least %{count} character(s)",
              [count: 7, validation: :length, kind: :min]},
             username: {"can't be blank", [validation: :required]}
           ],
           data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Payload<>,
           valid?: false
         >
       },
       errors: [],
       data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential<>,
       valid?: false
     >
   ]
 ]}

# parse_errors(cs_only) OUTPUT
# -----------------------------------------

[
  email: ["Email has invalid format"],
  password: ["Password should be at least 7 character(s)"],
  username: ["Username can't be blank"]
]

# {:errors, cs_with_other} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "aa@a.aaa", "password" => "lofa"})
# -----------------------------------------

{:errors,
 [
   invalid_changesets: [
     #Ecto.Changeset<
       action: nil,
       changes: %{
         payload: #Ecto.Changeset<
           action: :insert,
           changes: %{password: "lofa", username: "aa"},
           errors: [
             password: {"should be at least %{count} character(s)",
              [count: 7, validation: :length, kind: :min]}
           ],
           data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Payload<>,
           valid?: false
         >
       },
       errors: [],
       data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential<>,
       valid?: false
     >
   ],
   email_already_taken: "aa@a.aaa",
   username_already_taken: "aa"
 ]}

# parse_errors(cs_with_other) OUTPUT
# -----------------------------------------

[
  password: ["Password should be at least 7 character(s)"],
  email: ["Email address aa@a.aaa already exists."]
]
```

More details:

```elixir
##################################################################
# `keywords` = [{:error_msg, maybe_list}]
##################################################################
def parse_errors(keywords) do

  parsed_errors =
    Enum.map(
      keywords,
      ##################################################################
      # Each clause returns a keyword list.
      ##################################################################
      fn
        ({:email_already_taken, email}) -> email_taken_keyword(email)

        ({:username_already_taken, _})  -> []

        ({:invalid_changesets, changesets}) ->
          Enum.reduce(changesets, %{}, fn(changeset, acc) ->
            ##################################################################
            # #Ecto.Changeset<
            #   action: nil,
            #   changes: %{
            #     payload: #Ecto.Changeset<
            #       action: :insert,
            #       changes: %{password: "lofa"},
            #       errors: [
            #         password: {"should be at least %{count} character(s)",
            #          [count: 7, validation: :length, kind: :min]},
            #         username: {"can't be blank", [validation: :required]}
            #       ],
            #       data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential.Payload<>,
            #       valid?: false
            #     >
            #   },
            #   errors: [],
            #   data: #Aquir.Accounts.Commands.AddUsernamePasswordCredential<>,
            #   valid?: false
            # >
            ##################################################################
            changeset
            |> Ecto.Changeset.traverse_errors(&reduce_errors/3)
            ##################################################################
            # %{
            #   payload: %{
            #     password: ["Password should be at least 7 character(s)"],
            #     username: ["Username can't be blank"]
            #   }
            # }
            ##################################################################
            |> unwrap_add_credential_payload()
            |> Map.merge(acc)
          end)
          ##################################################################
          # The reduced  result  is a flat map,
          # therefore generating a keyword list
          # from it is simple.
          ##################################################################
          |> Map.to_list()
      end)

  case List.flatten(parsed_errors) do
    []    -> nil
    other -> other
  end
end
```

### 2019-01-24_0929 TODO (Translate error messages with `Gettext`)

... and  figure out  where the documentation  is for
that matter. Is it generated with a Phoenix project?

### 2019-01-24_1208 TODO (Make `error_tag/2` accessible)

Make  proper visual  and  non-visual  tags that  are
accessible.

### 2019-01-24_1339 TODO (release and deployment)

Plan for deployment and make a proper release.
http://blog.plataformatec.com.br/2016/07/understanding-deps-and-applications-in-your-mixfile/

Make  sure  that  production Comeonin  settings  are
secure!

### 2019-01-24_1437 NOTE (Why Jason necessitated `Map.from_struct/1` -> `from/1` switch)

Jason is stricter than  Poison, and all structs have
to have an  explicit `Jason.Encoder` implementation.
The   `Payload`  embed   (i.e.,  nested   schema  in
`AddUsernamePasswordCredential`)  is only  important
during  command validation,  but unimportant  during
persisting   the  event,   therefore  removing   the
`Payload` label with `from/1` (the recursive version
of `Map.from_struct/1`).

### 2019-01-24_1500 TODO (Make dependent commands execute in a transaction)

(Failing to load /users even if nothing has changed)

`RegisterUser`  and  `AddUsernamePasswordCredential`
commands  are   executed  together,  but   it  could
happen  (see 2019-01-24_1437,  where  the Poison  ->
Jason  change   caused  an  error   when  persisting
the  `UsernamePasswordCredentialAdded`  event. As  a
result,   `/users`  (`user/index.html.eex`)   failed
because it  was unable retrieve `username`  from the
read model.


### 2019-01-25_0749 NOTE (Illogical to check for no errors)

`AquirWeb.UserController.parse_errors/1` should only be invoked if there are errors. If an `Accounts` (or any other) context funtion returns an `{:errors, _}` tuple with an empty list then that is a design error and should be addressed.

### 2019-01-25_0851 NOTE (Why `reduce` and some explanation)

Why `reduce` when updating `state`:

```text
iex(25)> state = %{a: MapSet.new(["aa", "bb"]), b: MapSet.new(["cc", "dd"])}
iex(26)> keywords = [a: "ee", b: "ff"]
iex(27)> keywords = [a: "ee", b: "ff"]

iex(28)> Enum.each(keywords, fn({key, value}) -> Map.update(state, key, MapSet.new([value]), &MapSet.put(&1, value)) end)
:ok

iex(30)> Enum.map(keywords, fn({key, value}) -> Map.update(state, key, MapSet.new([value]) , &MapSet.put(&1, value)) end)
[
  %{a: #MapSet<["aa", "bb", "ee"]>, b: #MapSet<["cc", "dd"]>},
  %{a: #MapSet<["aa", "bb"]>, b: #MapSet<["cc", "dd", "ff"]>}
]
```

```elixir
# end of Unique.claim/1
#######################
case length(reserved_keywords) do
  0 ->
    new_state =
      # `state` is a map configured and populated at compile
      # time (see moduledoc).
      Enum.reduce(keywords, state, fn({key, value}, state_acc) ->
        Map.update!(  # if key is not in state, then
                      # + `claim` is called incorrectly
                      # + an entity should be in Unique
          state_acc,
          key,
          &MapSet.put(&1, value)) # updating the MapSet belonging to `key`
      end)
    {false, new_state}
  _ ->
    # get, new_state
    {{true, reserved_keywords}, state}
end
```

### 2019-01-25_1547 QUESTION (Adding 201 and Location does weird stuff)

Inserting the snippet below to the QUESTION location results in weird stuff. For example:

+ adding  all three  lines, the  functionality is  the
  same  but the  URL will  remain `/users`  instead of
  `/users/{username}`

+ commenting  out `render`  to user  `redirect`, there
  will be a notice that you are being redirected.

```elixir
|> put_status(:created)
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location
|> put_resp_header("location", Routes.user_path(conn, :show, username))
|> render("show.html", user: user_with_credentials)
```

ANSWER:
https://elixirforum.com/t/you-are-being-redirected-when-redirecting-from-phoenix-controller/16903

To redirect, the status code  has to be 301/302 etc.
I was trying to be  pedantic with the 201 but that's
probably more important for an API. (And indeed, the
above snippet was auto-generated  via mix for a JSON
API.)

### 2019-01-28_0536 NOTE (Why not simply `AddCredential`?)

Adding  a credential  has  a `type`  field, so  this
seems redundant,  but because commands  are distinct
modules, adding another  credential type would clash
if tried  to name  to `AddCredential` as  well (even
though the  `type` fields differ). Plus,  it is more
descriptinve this way. Event though commands are not
persisted, the  events generated are (with  the same
module concerns and  equally descriptive names), and
commands could also be saved  at one point for audit
purposes.

### 2019-01-28 NOTE (Issues on decoupling commands)

Some thoughts while trying to figure out on how to make `RegisterUser` and `AddUsernamePasswordCredential` commands independent:

**Total independence may not be possible?**  
1:N and N:M relationships  do require storing an ID.
`AddUsernamePasswordCredential`  has to  refer to  a
user,  otherwise there's  no  way to  know who  that
username belongs  to. If  it would  be 1:1,  the two
aggregates could  be merged  and having a  single ID
means that any subsequent  command updates a certain
field.

It would be possible to  have certain fields to hold
a  list, but  then  an operation  would  have to  be
defined as  for what to  do (i.e., add to  the list,
update item) that would  defeat the whole purpose of
event  sourcing. Handling  credentials and  users as
separate aggregates makes it easiser to manage and a
user  aggregate instance  doesn't have  to know  how
many  credentials it  has;  we have  the read  model
projection for that.

The current state of the aggregate is important when
dispatching  commands  and  the  aggregate  module's
`execute/2`  and `apply/2`  functions  are there  to
decide what  to do  on certain  preconditions (i.e.,
aggregate's state).

### 2019-01-28_0847 TODO NOTE (No `user_id` and `type`?)

`ResetPassword`  updates   an  existing  credential,
therefore  those  values  are already  part  of  the
aggregate instance and are not necessary.

On the  other hand, more  info is always  welcome so
these may be added to the metadata in the future.

### 2019-01-28_0923 TODO (Re-think password reset)

When do users usually reset passwords?
1. forgotten
2. compromised (or just want to change)

Re-think this  whole command as  it may needs  to be
split  in  more,  because scenario  1.  means  users
need  to  be  authenticated by  other  means  (email
confirmation), and 2. assumes that users are already
logged in.

### 2019-01-28_0926 TODO (Share Credential changesets)

!!! DO 2019-01-28_0923 FIRST AND RE-EVALUATE THIS !!!

Password   (and    other)   field    validation   is
the    same     as    for     `ResetPassword`    and
`AddUsernamePasswordCredential`   so  rounding   out
`ResetPassword` with payload  would make it possible
to  create a  "helper" section  in the  `Credential`
aggregate for creating changesets for both.

### 2019-01-29_0603 TODO (Strengthen password checks)

https://hexdocs.pm/comeonin/Comeonin.Bcrypt.html#add_hash/2
> Alternatively,  you could  use a  dedicated password
> strength checker, such as not_qwerty123.
>
> For more information  about password strength rules,
> see the latest NIST guidelines.

### 2019-01-29_0804 NOTE ("(ArgumentError) structs expect an :id key..." lofasz)

The  `_path/?`   helpers  either  expect   a  struct
with  an  `:id`  field  (or with  another  field  if
`Phoenix.Params`   if  derived   for  that   struct)
or  an  explicit  value.  So  far  I  always  passed
values  explicitly an  then  following  the book,  I
assigned the entire `%Schemas.User{}` instead of the
username.


### 2019-01-29_0816 QUESTION (Use cases to keep the session after a logout?)

> This  time  we’re   invoking  configure_session  and
> setting  :drop  to  true   ,  which  will  drop  the
> whole  session at  the end  of the  request. If  you
> want  to keep  the  session around,  you could  also
> delete  only  the  user ID  information  by  calling
> delete_session(conn, :user_id) .


