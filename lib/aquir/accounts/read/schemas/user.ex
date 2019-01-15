defmodule Aquir.Accounts.Read.Schemas.User do
  use Ecto.Schema

  alias Aquir.Accounts.Read.Schemas, as: RS

  @primary_key {:user_id, :binary_id, autogenerate: false}

  schema "users" do
    field :name,  :string
    field :email, :string, unique: true

    has_many :credentials, RS.Credential

    timestamps()
  end
end
