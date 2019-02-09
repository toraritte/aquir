defmodule Aquir.Users.Commands.AddUser do

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :user_id,    :binary_id
    field :contact_id, :binary_id
  end

  import Ecto.Changeset

  def changeset(%__MODULE__{} = command, params) do

    required_fields = [
      :user_id,
      :contact_id,
    ]

    command
    # 2019-02-05_0612 NOTE (Why generate UUIDs in the context and not in commands?)
    |> cast(params, required_fields)
    |> validate_required(required_fields)
  end
end
