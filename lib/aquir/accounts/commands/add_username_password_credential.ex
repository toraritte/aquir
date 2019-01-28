defmodule Aquir.Accounts.Commands.AddUsernamePasswordCredential do
  use Ecto.Schema

  # 2019-01-09_1200 TODO (`build_schema` macro)
  # 2019-01-28_0536 NOTE (Why not simply `AddCredential`?)

  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    # 2019-01-28 NOTE (Issues on decoupling commands)
    field :user_id,       :binary_id
    field :type,          :string, default: "username_password"

    # Even embeds add an `:id` primary key automatically.
    # See docs for `Ecto.Schema.embeds_*/3`.
    embeds_one :payload, Payload, primary_key: false do
      field :username,      :string
      field :password,      :string, virtual: true
      field :password_hash, :string
    end
  end

  import Ecto.Changeset

  def changeset(%__MODULE__{} = command, params) do

    required_fields = [
      :credential_id,
      :user_id,
      :payload,
    ]

    command
    # |> Aquir.Commanded.Support.assign_id(:credential_id)
    |> cast(params, [:user_id])
    |> cast_embed(:payload, with: &payload_changeset/2)
    |> validate_required(required_fields)
  end

  defp payload_changeset(payload, params) do

    required_fields = [:username, :password]

    payload
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> validate_length(:password, min: 7)
    |> Aquir.Accounts.Support.Auth.secure_password(:password)
  end
end
