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

  # TODO: inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.
  @doc """
  Validates  the  command   struct  against  arbitrary
  input  (`attrs`). The  transformation  process in  a
  valid  case is:
  "command(empty)" -> "changeset" -> "command(with_params)".
  """
  def imbue_command(%command{} = command_struct, attrs) do

    changeset = command.changeset(command_struct, attrs)

    case changeset.valid? do
      true ->
        command = struct(command, changeset.changes)
        {:ok, command}
      false ->
        {:error, changeset.errors}
    end
  end

end
