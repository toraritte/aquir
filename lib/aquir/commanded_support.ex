defmodule Aquir.CommandedSupport do

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

  # NOTE 2018-12-31_1019
  # TODO(?)
  @doc """
  There is a simmetry between commands and events, and
  duplicated  code with  that it  seems. The  commands
  are changesets  that produce  almost the  same event
  structs, and  aggregate `apply`s and  `execute`s are
  basically just  conversions from  one struct  to the
  other. (See `Aquir.Accounts.Aggregates.User`.)

  Projections  mirror the  commands even  more so,  as
  they are changesets themselves  as well, as they are
  basically commands persisted into  the DB as current
  state. (That is, commands -> events -> projections.)

  But of course, I just realized that a projection can
  combine many more command fields.
  """
  def convert_struct(from, to) do
    from
    |> Map.from_struct()
    |> (&struct(to, &1)).()
  end
end
