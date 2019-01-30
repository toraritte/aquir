defmodule Aquir.Accounts.Read.Schemas.UsernamePasswordCredential do
  use Ecto.Schema

  alias Aquir.Accounts.Read.Schemas, as: RS

  # See 2019-01-14_1317 for schema fields/table columns.
  @primary_key {:credential_id, :binary_id, autogenerate: false}

  # 2019-01-30_0627 NOTE (Why the users_credentals -> username_password_credentials migration?)
  # 2019-01-30_0628 NOTE (Credential :type field flip-flop)
  schema "username_password_credentials" do
    field :username,      :string, unique: true
    field :password_hash, :string

    # 2019-01-29_1459 NOTE ("user_user_id" Ecto assoc nerverack)
    belongs_to :user, RS.User,
      references:  :user_id,
      type:        :binary_id,
      foreign_key: :user_id

    timestamps()
  end
end
