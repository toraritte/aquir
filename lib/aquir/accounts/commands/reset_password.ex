defmodule Aquir.Accounts.Commands.ResetPassword do
  use Ecto.Schema

  # TODO This is probably oversimplified again. It would
  # be prudent to match the prevoius password to be more
  # secure and :password should be :new_password.
  @primary_key {:email, :string, autogenerate: false}

  embedded_schema do
    field :password,      :string, virtual: true
    field :password_hash, :string, default: ""
  end

  import Ecto.Changeset

  def changeset(command, params \\ %{}) do

    # TODO: add tests and add password constraints

    required_fields = [
      :email,
      :password
    ]

    command
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> Aquir.Accounts.Commands.Support.secure_password()
  end
end
