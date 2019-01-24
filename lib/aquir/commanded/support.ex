defmodule Aquir.Commanded.Support do

  # TODO(?): inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.

  alias Ecto.Changeset
  alias Aquir.Accounts.Commands, as: C

  defp generate_changeset(%command{} = command_struct, attrs) do
    command.changeset(command_struct, attrs)
  end

  # See (Evolution of `imbue_command`) NOTEs
  # [command_struct, attrs_map] ->
  #     {:ok,    [command]}
  #   | {:error, [command_changeset]}
  def imbue_commands(
    [ {                 %C.RegisterUser{} = r_struct, r_attrs},
      {%C.AddUsernamePasswordCredential{},            a_attrs},
    ]
  ) do

    make_add_changeset =
      fn(user_id) ->
        %C.AddUsernamePasswordCredential{for_user_id: user_id}
        |> generate_changeset(a_attrs)
      end

    r_changeset = generate_changeset(r_struct, r_attrs)

    case r_changeset.valid? do

      true  ->
        r_command   = Changeset.apply_changes(r_changeset)
        a_changeset = make_add_changeset.(r_command.user_id)

        case a_changeset.valid? do
          true  ->
            {:ok, [r_command, Changeset.apply_changes(a_changeset)]}
          false ->
            {:error, [a_changeset]}
        end

      false ->
        # The uuid  is only a placeholder  to return changeset
        # validation  errors.  (Remember, returning  :ok  only
        # when  both commands  succeed,  therefore this  value
        # will always be discarded; we just need the errors!)
        a_changeset = make_add_changeset.(Ecto.UUID.generate())

        case a_changeset.valid? do
          true ->
            {:error, [r_changeset]}
          false ->
            {:error, [r_changeset, a_changeset]}
        end
    end
  end

  # (FP sidenote: this is like an "either", right?

  # USE CASE: for independent commands
  # [command_struct, attrs_map] ->
  #     {:ok,    [command]}
  #   | {:error, [command_changeset]}
  def imbue_commands(command_param_tuples) when is_list(command_param_tuples) do

    applied_changesets =
      Enum.map(
        command_param_tuples,
        fn({%command{} = command_struct, attrs}) ->
          changeset = command.changeset(command_struct, attrs)
          case changeset.valid? do
            true ->
              # command_with_params = struct(changeset.data, changeset.changes)
              Changeset.apply_changes(changeset)
            false ->
              changeset
          end
        end)

    filtered_errors =
      Enum.filter(
        applied_changesets,
        fn
          (%Changeset{}) -> true
                     (_) -> false
        end)

    case length(filtered_errors) do
      0 -> {:ok, applied_changesets} # i.e., valid commands at this point
      _ -> {:error, filtered_errors}
    end
  end

  # 2019-01-24_1437 NOTE

  @doc """
  Convert from one type of struct to another.
  """
  def convert_struct(from, to) do
    # 2019-01-24_1437 NOTE
    # (Why Jason necessitated `Map.from_struct/1` -> `from/1` switch)
    struct(to, from(from))
    # struct(to, Map.from_struct(from))

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

  # 2019-01-11_0526 TODO
  @doc """
  Take a look at the `__using__/1` example at
  https://hexdocs.pm/ecto/Ecto.Schema.html#module-schema-attributes

  It  is   a  good   convention  to  use,   and  would
  be  the  perfect  place  to  put  additional  schema
  functionality. For example, only events would derive
  `Poison.Encoder` or  the functions/macros  to "copy"
  fields from the aggregate schema.

  IDEA: (include copying fields in `use` examples)
  Use `__using__/1` options to mark what the schema is
  used:

  ```elixir
  defmodule Bla.Events.ThisHappened
    use Aquir.Schema, for: :event
  ```
  or
  ```elixir
  defmodule Bla.Projections.ThisHappened
    use Aquir.Schema, for: :projection
  ```
  It wouldn't probably be hard to recognize the module
  names and invoke the right  macro clause, but I like
  explicit stuff.

  Related notes:
  + 2019-01-04_1152
  + 2019-01-09_1200
  + 2018-12-31_1019
  + 2018-10-23_0914
  """
  defmacro build_schema do
  end

  defmacro __using__(opts) do
    quote do
      @derive Jason.Encoder
    end
  end
end
