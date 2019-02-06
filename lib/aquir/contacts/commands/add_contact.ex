defmodule Aquir.Contacts.Commands.AddContact do

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :contact_id,  :binary_id
    field :first_name,  :string
    field :middle_name, :string
    field :last_name,   :string
  end

  import Ecto.Changeset

  def changeset(%__MODULE__{} = command, params) do

    required_fields = [
      :contact_id,
      :first_name,
      :last_name,
    ]


    command
    # 2019-02-05_0612 NOTE (Why generate UUIDs in the context and not in commands?)
    |> cast(params, required_fields)
    |> validate_required(required_fields)
  end
end
