defmodule Aquir.Accounts.Aggregates.Support do

  def convert_similar_structs(from, to) do
    from
    |> Map.from_struct()
    |> (&struct(to, &1)).()
  end
end
