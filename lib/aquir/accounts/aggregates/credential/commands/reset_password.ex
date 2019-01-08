defmodule Aquir.Accounts.Aggregates.Credential.Commands.ResetPassword do
  use Ecto.Schema

  # TODO This is probably oversimplified again. It would
  # be prudent to match the prevoius password to be more
  # secure.

  # TODO missing for_user_id and credential_id
  @primary_key false
  embedded_schema do
    field :username,      :string
    field :new_password,  :string, virtual: true
    field :password_hash, :string, default: ""
  end

  import Ecto.Changeset

  def changeset(command, params \\ %{}) do

    # TODO: add tests and add password constraints

    required_fields = [
      :email,
      :new_password
    ]

    command
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> Aquir.Accounts.Auth.secure_password(:new_password)
  end
end