defmodule Aquir.Accounts.Commands.RegisterUser do
  use Ecto.Schema

  # NOTE:  Seen  several  places  that  it  is
  # recommended  to  treat  credentials  as  a  separate
  # module (context  even, if  it is justified)  so that
  # different authentication schemes could be added more
  # easily in  the future.  That is, separate  DB tables
  # and a somewhat more complicated schema and migration
  # with relationships.
  #
  # With CQRS/ES, this  would be done by  creating a new
  # command and  event, and the projection(s)  can be as
  # complicated  as one  likes. Commands  can also  emit
  # multiple events, simplifying the refactor a bit.

  # Why the use of `embedded_schema/1`:
  # https://stackoverflow.com/questions/52799805

  # See main README on `@primary_key` usage in this project.
  @primary_key {:user_uuid, Ecto.UUID, autogenerate: false}

  # Adding the `virtual` option to the `:password` field
  # has  no  significance;  it only  documents  that  it
  # would not  be persisted  in the projection.  See the
  # `Projections.User` schema, it isn't even listed.
  embedded_schema do
    field :email,           :string
    field :password,        :string, virtual: true
    field :hashed_password, :string, default: ""
  end

  import Ecto.Changeset

  def hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pw}} ->
        hash = Comeonin.Bcrypt.hashpwsalt(pw)
        put_change(changeset, :hashed_password, hash)
      _ ->
        changeset
    end
  end

  def assign_uuid(changeset) do
    case changeset.valid? do
      true ->
        uuid = Ecto.UUID.generate()
        put_change(changeset, :user_uuid, uuid)
      false ->
        changeset
    end
  end

  def changeset(command, params \\ %{}) do

    # TODO: tests!

    # TODO: validations for "email"

    # TODO: separate credentials and user info
    required_fields = [
      :email,
      :password,
    ]

    # { command, types }
    command
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    |> assign_uuid()
    |> hash_password()
  end
end
