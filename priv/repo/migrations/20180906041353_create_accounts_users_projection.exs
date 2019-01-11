defmodule Aquir.Repo.Migrations.CreateAccountsUsersProjection do
  use Ecto.Migration

  # 2019-01-10_0725 NOTE Migration name change TODO
  @doc """
  The migration  for the `User` projection  was called
  `:accounts_users` (with a database table of the same
  name),  but (right  now) it  doesn't seem  useful to
  make the  context's name  part of the  table's name.
  The projections can be derived  in any way one wants
  them, that's the whole point of ES, isn't it?

  Also,  aggregates have  their own  processes holding
  their  own states  (presumably), and  the [Commanded
  guide "Aggregates"](https://github.com/commanded/commanded/blob/v0.17.2/guides/Aggregates.md#aggregate-state-snapshots)
  seems to  confirm it stating  that a snapshot  is an
  optimization solution  so that not all  events would
  have to be replayed when the server is restarted:

  > A snapshot  represents the aggregate state  when all
  > events to that point in time have been replayed. You
  > can  optionally  configure  state  snapshotting  for
  > individual  aggregates  in your  app  configuration.
  > Instead of loading every event for an aggregate when
  > rebuilding  its state,  only  the  snapshot and  any
  > events  appended since  its  creation  are read.  By
  > default snapshotting is disabled for all aggregates.

  > As  an example,  assume a  snapshot was  taken after
  > persisting  an event  for the  aggregate at  version
                    vvvvvvvvvvvvvvvvvv
  > 100.  When the  aggregate  process  is restarted  we
                    ^^^^^^^^^^^^^^^^^^
  > load  and  deserialize  the  snapshot  data  as  the
  > aggregate's initial state. Then  we fetch and replay
  > the aggregate's events after version 100.

  See QUESTION 2019-01-10_0752 also.
  """

  def change do
    # https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3-case-sensitivity
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:accounts_users, primary_key: false) do
      add :user_id,       :uuid, primary_key: true
      add :email,         :citext
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:accounts_users, [:email])
  end
end
