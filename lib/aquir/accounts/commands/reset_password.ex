defmodule Aquir.Accounts.Commands.ResetPassword do
  use Ecto.Schema

  # TODO This is probably oversimplified again. It would
  # be prudent to match the previous password to be more
  # secure.

  # see 2019-01-09_1200
  @primary_key false
  embedded_schema do
    # Why the `:credential_id`? See 2019-01-15_1223
    field :credential_id, :binary_id
    field :username,      :string
    field :new_password,  :string, virtual: true
    field :password_hash, :string
  end

  import Ecto.Changeset

  def changeset(payload, params) do

    required_fields = [
      :credential_id,
      :username,
      :new_password
    ]

    payload
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> Aquir.Accounts.Support.Auth.secure_password(:new_password)
  end
end
