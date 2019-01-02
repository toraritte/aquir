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

  # TODO
  @doc """
  Seen several places that  it is recommended to treat
  credentials as  a separate module (context  even, if
  it  is justified)  so that  different authentication
  schemes could  be added  more easily in  the future.
  That  is, separate  DB  tables and  a somewhat  more
  complicated schema and migration with relationships.

  With CQRS/ES, this  would be done by  creating a new
  command and  event, and the projection(s)  can be as
  complicated  as one  likes. Commands  can also  emit
  multiple events, simplifying the refactor a bit.

  See main README on `@primary_key` usage in this project.
  """

  @primary_key {:user_id, Ecto.UUID, autogenerate: false}

  # Why the use of `embedded_schema/1`?
  @doc """
  See https://stackoverflow.com/questions/52799805

  Adding the `virtual` option to the `:password` field
  has  no  significance;  it only  documents  that  it
  would not  be persisted  in the projection.  See the
  `Projections.User` schema, it isn't even listed.
  """
  embedded_schema do
    field :email,           :string
    field :password,        :string, virtual: true
    field :password_hash,   :string, default: ""
  end

  import Ecto.Changeset

  defp assign_user_id(changeset) do
    case changeset.valid? do
      true ->
        uuid = Ecto.UUID.generate()
        put_change(changeset, :user_id, uuid)
      false ->
        changeset
    end
  end

  def changeset(command, params \\ %{}) do

    # TODO:
    # + add tests and email, password constraints
    #   (these could be in Support)
    # + separate credentials and user info
    required_fields = [
      :email,
      :password,
    ]

    command
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> assign_user_id()
    |> Aquir.Accounts.Auth.secure_password(:password)
  end
end
