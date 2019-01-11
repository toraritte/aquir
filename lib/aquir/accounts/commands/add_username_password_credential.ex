defmodule Aquir.Accounts.Commands.AddUsernamePasswordCredential do
  use Ecto.Schema

  # 2019-01-09_1200 TODO
  @doc """
  Related notes:
  + 2019-01-04_1152
  + 2019-01-09_1200
  + 2018-12-31_1019
  + 2018-10-23_0914

  Another take on making a `build_schema` macro:

  + allows  copying fields into  the events/commands
    from the aggregate
    => corollary: document  in events/commands which
       aggregate they belong to

  + ID  is autogenerated,  and so  far it  is always
    <aggregate-name>_id
  """
  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    field :for_user_id,   :binary_id
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

  def changeset(command, params) do

    command
    |> Aquir.Commanded.Support.assign_id(:credential_id)
    |> cast(params, [:for_user_id])
    |> cast_embed(:payload, with: &payload_changeset/2)
    |> validate_required([:credential_id, :for_user_id, :payload])
  end

  defp payload_changeset(payload, params) do

    required_fields = [:username, :password]

    payload
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> Aquir.Accounts.Auth.secure_password(:password)
  end
end
