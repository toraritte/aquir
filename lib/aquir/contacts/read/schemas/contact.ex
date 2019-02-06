defmodule Aquir.Contacts.Read.Schemas.Contact do
  use Ecto.Schema

  alias Aquir.Contacts.Read.Schemas, as: RS

  @primary_key {:contact_id, :binary_id, autogenerate: false}

  schema "contacts" do
    field :first_name,  :string
    field :middle_name, :string
    field :last_name,   :string

    has_many :email, RS.Email,
      references:  :contact_id,
      foreign_key: :contact_id

    timestamps()
  end
end
