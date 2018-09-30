defmodule Aquir.Accounts.Commands.RegisterUser do

  defstruct [
    :user_uuid,
    :username,
    :email,
    :hashed_password
  ]

  import Ecto.Changeset

  def changeset(command \\ %__MODULE__{}, attrs) do

    # TODO: tests!

    # TODO: validations for "email" and "username"

    types = %{
      user_uuid: Ecto.UUID,
      username:  :string,
      email:     :string,
      hashed_password: :string,
    }

    required_fields = Map.keys(types)

    { command, types }
    |> cast(attrs, required_fields)
    |> validate_required(required_fields)
  end
end
