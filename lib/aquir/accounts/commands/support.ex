defmodule Aquir.Accounts.Commands.Support do

  import Ecto.Changeset

  def secure_password(changeset) do

    # Not checking for `changeset.valid?` because we would
    # have to pattern match anyway for the password.
    case changeset do

      %Ecto.Changeset{valid?: true, changes: %{password: pw}} ->
        changeset
        |> put_change(:password_hash, Comeonin.Bcrypt.hashpwsalt(pw))
        |> put_change(:password, nil)

      _ ->
        changeset

    end
  end

  # TODO(?): inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.

  @doc """
  First,   `imbue_command/2`   validates   a   command
  changeset against arbitrary input (`attrs`). Second,
  the  command  struct  is  enriched  with  the  input
  if  validation  succeeds. Returns  changeset  errors
  otherwise.
  """
  def imbue_command(%command{} = command_struct, attrs) do

    changeset = command.changeset(command_struct, attrs)

    case changeset.valid? do
      true ->
        command_with_params = struct(command, changeset.changes)
        {:ok, command_with_params}
      false ->
        {:error, changeset.errors}
    end
  end

end
