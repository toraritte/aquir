defmodule Aquir.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  # 2019-01-10_0725 NOTE Migration name change TODO

  def change do
    # https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3-case-sensitivity
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:users, primary_key: false) do
      add :user_id, :uuid, primary_key: true

      add(:contact_id,
        references(
          "contacts",
          type: :uuid,
          column: :contact_id,
          on_delete: :delete_all
        )
      )

      timestamps()
    end
    # no unique constraints
  end
end
