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

  @doc """
  Why the use of `embedded_schema/1`?
  -----------------------------------

  See https://stackoverflow.com/questions/52799805 and
  the project README also.

  No primary keys for event and command schemas
  ===============================================

  Primary  key is  discarded because  `Ecto.Schema` is
  only  used  for  data  validation  in  commands  and
  events. Projections reflect the  current state of an
  aggregate, and  their schemas  do use  primary keys.
  Projectors will  cast events  into their  final form.

  The current flow:
  ```
  Command schema -> Event struct -> Projector (Event struct -> Projection schema)

  Legend: `->` - simple conversion
  ```

  Use of `:virtual` fields
  ========================

  Adding the `virtual` option to the `:password` field
  has no significance; it only serves as a reminder to
  myself  that  it  would  not  be  persisted  in  the
  projection. The  changeset will  simply swap  it out
  with a  hashed version (`:password_hash`).  See also
  the `Projections.User` schema, it isn't even listed.

  `:binary_id` vs `Ecto.UUID`
  ===========================

  `:binary_id`    vs   `Ecto.UUID`    can   be    used
  interchangeably in **schemas**  but using the former
  as it  more general. The `user_id`  is generated via
  `Ecto.UUID` anyway.
  https://hexdocs.pm/ecto/Ecto.Schema.html#module-primary-keys
  """
  @primary_key false
  embedded_schema do
    field :user_id,       :binary_id
    field :email,         :string
    field :password,      :string, virtual: true
    field :password_hash, :string, default: ""
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
