# Aquir

## 0. Notes on using `Ecto.Schema` in this project

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

See https://stackoverflow.com/questions/52799805 and the project README also.

#### 0.2.2 No primary keys for event and command schemas

Primary key is discarded because `Ecto.Schema` is only used for data validation in commands and events. Projections reflect the current state of an aggregate, and their schemas do use primary keys. Projectors will cast events into their final form.

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

## Miscellaneous

### Resetting both the Ecto projections, and the EventStore

```
$ mix do ecto.drop, ecto.create, ecto.migrate
$ mix do event_store.drop, event_store.create, event_store.init
```

(It did work all of these tasks on one line and then it didn't, then again it did, etc. This way seemed to be the most robust so far.)

## Start project

(TODO: update project generation from console history)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
