defmodule Aquir.Accounts.Commands.ResetPassword do
  use Ecto.Schema

  # 2019-01-28_0923 TODO (Re-think password reset)

  @primary_key false
  embedded_schema do
    # Why the `:credential_id`? See 2019-01-15_1223
    field :credential_id, :binary_id
    field :username,      :string
    field :new_password,  :string, virtual: true
    field :password_hash, :string
    # 2019-01-28_0847 NOTE TODO (No `user_id` and `type`?)

    # 2019-01-28_0926 TODO (Share Credential changesets)
    # embeds_one :payload, Payload, primary_key: false do
    #   field :username,      :string
    #   field :new_password,  :string, virtual: true
    #   field :password_hash, :string
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
    |> Aquir.Accounts.Auth.secure_password(:new_password)
  end
end
