defmodule Aquir.Repo.Migrations.CreateContactsEmails do
  use Ecto.Migration

  def change do

    create table(:contacts_emails, primary_key: false) do
      add :email_id, :uuid,   primary_key: true
      add :email,    :string, null: false
      add :type,     :string, null: false

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

    create unique_index(:contacts_emails, [:email])
  end
end
