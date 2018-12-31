defmodule Aquir.Accounts.Aggregates.Support do

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
