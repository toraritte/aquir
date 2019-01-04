defmodule Aquir.Commanded.Support do

  # TODO(?): inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.

  # TODO 2019-01-03_1117
  @doc """
  specify   typespec    for   `imbue_command`.   Won't
  be   straightforward  as   `Ecto.Schema`  does   not
  automatically  generate   a  type  when   used.  See
  discussions on Elixir Forum  or in TypedStruct issue
  #5:
  https://github.com/ejpcmac/typed_struct/issues/5
  """

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

  # TODO(?) 2018-12-31_1019
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

  UPDATE 2019-01-14_0724
  ======================
  + Aquir.Accounts.Aggregates.User
  + Aquir.Accounts.Commands.RegisterUser
  + Aquir.Accounts.Events.UserRegistered

  These structs are (almost) identical and they define
  the same  structure multiple  times; the  only thing
  that differs is the  struct's (i.e., module's) name.
  In Haskell(-like)  languages a record would  just be
  tagged and  re-packed whenever needed.  For example,
  data  validation is  done  on `RegisterUser`  before
  conversion  to `UserRegistered`,  but that  could be
  part of the re-packing process.

  Take  a  look  at   Witchcraft  and  Algae.  (Purerl
  would probably  be a  much bigger leap,  leaving the
  entire Elixir  ecosystem behind.  Or maybe  not? The
  underlying system is Erlang for both anyway.
  """

  @doc """
  Convert from one type of struct to another.
  """
  def convert_struct(from, to) do
    struct(to, Map.from_struct(from))
    # Leaving this for posterity that piping is nice
    # but it can be overdone.
    #
    # from
    # |> Map.from_struct()
    # |> (&struct(to, &1)).()
  end
end
