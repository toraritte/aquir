# Aquir

## 0 Notes on using `Ecto.Schema` in this project

`Ecto.Schema` is used for validating commands and for projections. [This Stack Overflow question](https://stackoverflow.com/questions/52799805) documents the difference between `schema/2` and `embedded_schema/1`, but as soon as Ecto 3 is out, it will be in the main documentation as well.

### 0.1 Projections: (i.e., migrations and corresponding Ecto.Schema)

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

#### 0.2.1 Why the use of `embedded_schema/1`?

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

Legend: `->` - simple conversion
```

#### 0.2.3 Use of `:virtual` fields

Adding the `virtual` option to the `:password` field has no significance; it only serves as a reminder to myself that it would not be persisted in the projection. The changeset will simply swap it out with a hashed version (`:password_hash`). See also the `Projections.User` schema, it isn't even listed.

#### 0.2.4 `:binary_id` vs `Ecto.UUID`

`:binary_id` vs `Ecto.UUID` can be used interchangeably in **schemas** but using the former as it more general. The `user_id` is generated via `Ecto.UUID` anyway.

https://hexdocs.pm/ecto/Ecto.Schema.html#module-primary-keys

### 0.3 Resetting both the Ecto projections, and the EventStore

```
$ mix do ecto.drop, ecto.create, ecto.migrate
$ mix do event_store.drop, event_store.create, event_store.init
```

(It did work all of these tasks on one line and then it didn't, then again it did, etc. This way seemed to be the most robust so far.)

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
