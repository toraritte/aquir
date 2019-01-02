defmodule Aquir.Accounts.Commands.Support do

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
