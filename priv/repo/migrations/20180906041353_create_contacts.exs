defmodule Aquir.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    # https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3-case-sensitivity
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:contacts, primary_key: false) do
      add :contact_id, :uuid, primary_key: true
      add :first_name,  :citext, null: false
      add :middle_name, :citext
      add :last_name,   :citext, null: false

      timestamps()
    end
    # no unique constraints
  end
end
