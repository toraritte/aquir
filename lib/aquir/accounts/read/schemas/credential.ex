defmodule Aquir.Accounts.Read.Schemas.Credential do
  use Ecto.Schema

  alias Aquir.Accounts.Read.Schemas, as: RS

  # See 2019-01-14_1317 for schema fields/table columns.
  @primary_key {:credential_id, :binary_id, autogenerate: false}

  schema "users_credentials" do
    field :type,          :string
    field :username,      :string, unique: true
    field :password_hash, :string

    belongs_to :user, RS.User,
      references:  :user_id,
      type:        :binary_id

    timestamps()
  end
end
