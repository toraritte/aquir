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
