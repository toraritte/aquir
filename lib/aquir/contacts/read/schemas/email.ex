defmodule Aquir.Contacts.Read.Schemas.Email do
  use Ecto.Schema

  alias Aquir.Contacts.Read.Schemas, as: RS

  @primary_key {:email_id, :binary_id, autogenerate: false}

  schema "contacts_emails" do
    field :email, :string, unique: true
    field :type,  :string # work, personal, ?

    belongs_to :contact, RS.Contact,
      references:  :contact_id,
      type:        :binary_id,
      foreign_key: :contact_id

    timestamps()
  end
end
