defmodule Aquir.Repo.Migrations.CreateAccountsUsers do
  use Ecto.Migration

  def change do
    # https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3-case-sensitivity
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:accounts_users, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :username, :citext
      add :email,    :citext
      add :hashed_password, :string

      timestamps()
    end

    create unique_index(:accounts_users, [:username])
    create unique_index(:accounts_users, [:email])
  end
end
