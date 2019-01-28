defmodule Aquir.Accounts.Commands.RegisterUser do

  @moduledoc """
  Defines a command struct very similar to the corresponding `UserRegistered` event (another `struct`):

  ```elixir
  defstruct [
    :user_id,
    :email,
    :password,
    :password_hash
  ]
  ```
  """

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :user_id, :binary_id
    field :name,    :string
    field :email,   :string
  end

  import Ecto.Changeset

  def changeset(%__MODULE__{} = command, params) do

    # TODO:
    # + add tests and email, password constraints
    #   (these could be in Support)
    # + separate credentials and user info
    required_fields = [
      :user_id,
      :name,
      :email,
    ]

    command
    # |> Aquir.Commanded.Support.assign_id(:user_id)
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    # 2019-01-18_0000 (The reason for such meager validation)
    |> validate_format(:email, ~r/.+@.+\..{2,4}/)
  end
end
