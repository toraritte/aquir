defmodule Aquir.Commanded.Support do

  # TODO(?): inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.

  import Ecto.Changeset

  # See (Evolution of `imbue_command`) NOTEs

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
        # command_with_params = struct(changeset.data, changeset.changes)
        {:ok, apply_changes(changeset)}
      false ->
        {:error, changeset}
    end
  end

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

  def assign_id(struct, field) do
    Map.put(struct, field, Ecto.UUID.generate())
  end

  @doc """
  Recursive version of `Map.from_struct/1`
  """
  def from(struct) do
    map = Map.delete(struct, :__struct__)
    map_keys = Map.keys(map)
    Enum.reduce(
      map_keys,
      %{},
      fn(key, acc) ->
        s = Map.get(map, key)
        value =
          case is_map(s) && Map.has_key?(s, :__struct__) do
            true  -> from(s)
            false -> s
          end
        Map.put(acc, key, value)
      end
    )
  end

  defmacro build_schema do
  end

  defmacro __using__(opts) do
    quote do
      @derive Poison.Encoder
    end
  end
end
