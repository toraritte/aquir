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
  #     {:ok,    [command_changeset]}
  #   | {:error, [command_changeset]}
  def imbue_command(
    [ {                 %C.RegisterUser{} = r_struct, r_attrs},
      {%C.AddUsernamePasswordCredential{},            a_attrs},
    ]
  ) do

        # require IEx; IEx.pry
    make_add_changeset =
      fn(user_id) ->
        %C.AddUsernamePasswordCredential{for_user_id: user_id}
        |> generate_changeset(a_attrs)
      end

    r_changeset = generate_changeset(r_struct, r_attrs)

    result = []

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
  #     {:ok,    [command_changeset]}
  #   | {:error, [command_changeset]}
  def imbue_command(command_param_tuples) when is_list(command_param_tuples) do
  # def imbue_command(%command{} = command_struct, attrs) do

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

  # 2019-01-15_0523 NOTE
  @doc """
  The   only  reason   `Map.from_struct/1`  has   been
  replaced with `from/1` (its recursive equivalent) in
  `convert_struct/2`  is that  when converting  nested
  structs to  events, the key types  get inconsistent.
  Commands are schemas, events  are plain structs, but
  probably the real reason for  this issue is that the
  nested embedded schemas are  defined inline (to wit:
  `AddUsernamePasswordCredential`).

  Long story short, this command:

  ```elixir
  %Aquir.Accounts.Commands.AddUsernamePasswordCredential{
    credential_id: "1fea592b-a308-41be-a78c-dac38617ba81",
    for_user_id: "78ff3d89-c4dc-4f0e-96f4-b3ebde35c228",
    payload: %Aquir.Accounts.Commands.AddUsernamePasswordCredential.Payload{
      password: nil,
      password_hash: "$2b$12$HRDwYhqVXF3vcZy/L7hzIeTybskR/qZs.HNdREyz/t1ruw7sy0lRy",
      username: "lofa"
    },
    type: "username_password"
  }}
  ```

  becomes this event:

  ```elixir
  %Aquir.Accounts.Events.UsernamePasswordCredentialAdded{
    credential_id: "9c2de482-7671-4bfb-8a52-6d39f24ac8f4",
    for_user_id: "daa9f152-4e77-4131-9f2e-6b8ab4dbd511",
    payload: %{
      "password" => nil,
      "password_hash" => "$2b$12$Pl9yAyPYRuypwIfzqfTxXuiQfDtfffC5lAJKMgBuoOB8zlga9E11y",
      "username" => "aa"
    },
    type: "username_password"
  }
  ```

  and  won't  be  able  to use  the  dot  notation  on
  `payload`'s keys.

  --------------------------------------------------

  UPDATE: Nope,  that wasn't the issue.  It's just how
          it is I guess.
  """

  @doc """
  Convert from one type of struct to another.
  """
  def convert_struct(from, to) do
    # See 2019-01-15_0523 above.
    struct(to, Map.from_struct(from))
    # struct(to, from(from))

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
      @derive Poison.Encoder
    end
  end
end
