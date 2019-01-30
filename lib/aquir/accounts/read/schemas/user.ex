defmodule Aquir.Accounts.Read.Schemas.User do
  use Ecto.Schema

  alias Aquir.Accounts.Read.Schemas, as: RS

  # 2019-01-15_0918 TODO
  @doc """
  Most of the  IDs (`:user_id`, `credential_id`, etc.)
  are  mostly  for  Commanded aggregate  instances  to
  have their unique  identifier, therefore they should
  probably have the postfix `_aid`.

  They  are useful  as  read model  IDs  but they  may
  become  redundant at  one point.  For example,  each
  user  has a  unique  email address  and username  as
  well.
  """

  @primary_key {:user_id, :binary_id, autogenerate: false}

  schema "users" do
    field :name,  :string
    field :email, :string, unique: true

    # 2019-01-29_1459 NOTE ("user_user_id" Ecto assoc nerverack)
    # 2019-01-30_0627 NOTE (Why the users_credentals -> username_password_credentials migration?)
    has_one :credential, RS.UsernamePasswordCredential,
      references: :user_id,
      foreign_key: :user_id

    timestamps()
  end
end
