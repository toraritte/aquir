defmodule Aquir.Contacts.Commands.AddEmail do

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :email_id,   :binary_id
    field :contact_id, :binary_id
    field :email,      :string
    field :type,       :string # work, personal, ?
  end

  import Ecto.Changeset

  def changeset(%__MODULE__{} = command, params) do

    required_fields = [
      :email_id,
      :contact_id,
      :email,
      :type,
    ]

    command
    # 2019-02-05_0612 NOTE (Why generate UUIDs in the context and not in commands?)
    |> cast(params, required_fields)
    |> validate_required(required_fields)
       # 2019-01-18_0000 (The reason for such meager validation)
    |> validate_format(:email, ~r/.+@.+\..{2,4}/)
  end
end
