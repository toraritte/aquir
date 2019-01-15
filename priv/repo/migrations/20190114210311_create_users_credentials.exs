defmodule Aquir.Repo.Migrations.CreateUsersCredentials do
  use Ecto.Migration

  # 2019-01-14_1317 NOTE
  @doc """
  The  notion is  that this  table gets  extended with
  more and  more (nullable) columns when  new types of
  credentials are added (no clue what those would be).

  The `:username` and `:password` columns are nullable
  because they  are keys of the  maps of corresponding
  events and aggregate instances.  So when a new types
  of credential  comes along, the table  extended with
  columns  only  specific  to those  credentials,  and
  when they  are entered,  the not needed  columns are
  ignored.

  We'll see how this holds up in practice.
  ----------------------------------------------------

  UPDATE: It  should work.  Had  to  put a  `UNIQUE`
          constraint  on  username, but  that  still
          allows `null`  values. Also did  an insert
          omitting  `username`  and  `password_hash`
          and it went through.
  """
  def change do
    # https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3-case-sensitivity
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:users_credentials, primary_key: false) do
      add :credential_id, :uuid,   primary_key: true
      add :type,          :string, null: false
      add :username,      :string
      add :password_hash, :string
      add :for_user_id, references("users", type: :uuid, column: :user_id)

      timestamps()
    end

    create unique_index(:users_credentials, [:username])
  end
end
