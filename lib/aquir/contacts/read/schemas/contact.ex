defmodule Aquir.Contacts.Read.Schemas.Contact do
  use Ecto.Schema

  alias Aquir.Contacts.Read.Schemas, as: RS

  @primary_key {:contact_id, :binary_id, autogenerate: false}

  schema "contacts" do
    # 2019-02-07_1408 TODO (Multi-column index example in postgres docs!)
    field :first_name,  :string
    field :middle_name, :string
    field :last_name,   :string

    # 2019-02-07-1654 NOTE (contacts/users assoc clean up and contact_contact_id)
    has_many :emails, RS.Email,
      foreign_key: :contact_id

    has_one :user, Aquir.Users.Read.Schemas.User,
      foreign_key: :contact_id

    timestamps()
  end
end
