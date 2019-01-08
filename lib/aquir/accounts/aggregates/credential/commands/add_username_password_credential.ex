defmodule Aquir.Accounts.Aggregates.Credential.Commands.AddUsernamePasswordCredential do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    field :for_user_id,   :binary_id
    field :type,          :string, default: "username_password"

    # Even embeds add a `:id` primary key automatically.
    # See docs for `Ecto.Schema.embeds_*/3`.
    embeds_one :credential, Credential, primary_key: false do
      field :username,      :string
      field :password,      :string, virtual: true
      field :password_hash, :string
    end
  end

  import Ecto.Changeset

  def changeset(command, params) do

    command
    |> Aquir.Commanded.Support.assign_id(:credential_id)
    |> cast(params, [:for_user_id])
    |> cast_embed(:credential, with: &credential_changeset/2)
    |> validate_required([:credential_id, :for_user_id, :credential])
  end

  defp credential_changeset(credential, params) do

    required_fields = [:username, :password]

    credential
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> Aquir.Accounts.Auth.secure_password(:password)
  end
end
