defmodule Aquir.Repo.Migrations.CreateAccountsUsersProjection do
  use Ecto.Migration

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
