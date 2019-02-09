defmodule Aquir.Commanded.Support do

  # TODO(?): inject this with  a macro to every command
  # as it  is universal when using  `Ecto.Changeset` for
  # validation.

  alias Ecto.Changeset

  alias Aquir.Commanded.Support, as: ACS
  alias Aquir.Commanded.Router,  as: ACR

  def claim_and_imbue(
    command, # module name only
    params,
    claims: claims, # can be []
    consistency: consistency
  ) do
    maybe_command =
      command
      |> struct()
      |> imbue_command(params, consistency)

    # 2019-02-06_0601 NOTE (Why `Unique.check/1` before `claim/1`?)
    [
      maybe_command,
      Aquir.Unique.check(claims), # {:ok, _} if no claim (i.e., [])
    ]
  end

  def run_commands(mod_func_tuples, with: params) do
    Enum.map(fn({mod, func}) -> apply(mod, func, [params]) end)
  end

  def do_dispatch(results, on_success: {mod, func, params}) do

    filtered_errors = error_filter(results)

    with(
      # easier to check for bool than for other than zero in else
      true <- length(filtered_errors) == 0,

      {commands, claims} =
        Enum.reduce(
          results,
          {[],[]},
          fn
            ({:ok, :entities_free, keywords}, {cmds, clms}) ->
              {cmds, clms ++ keywords}
            (command, {cmds, clms}) ->
              {[command|cmds], clms}
          end),
      {:ok, :claim_successful, _} <- Aquir.Unique.claim(claims)
    ) do

      for {:ok, command, consistency} <- commands do
        ACR.dispatch(command, consistency: consistency)
      end
      apply(mod, func, params)

    else
      false ->
        {:errors, ACS.transform(filtered_errors)}
      {:error, :entities_reserved, _} = errors ->
        {:errors, errors}
    end
  end

  # def dispatch_commands(command_consistency_tuples) do
  #   for {command, consistency} <- command_consistency_tuples do
  #     ACR.dispatch(command, consistency: consistency)
  #   end
  # end

  def generate_uuids(n) do
    for _ <- 1..n, do: Ecto.UUID.generate()
  end

  def error_filter(result_list) do
    Enum.filter(
      result_list,
      fn(either_tuple) -> elem(either_tuple, 0) == :error end)
      # `either_tuple` is a tuple of arbitrary size with the
      # first element being either `:ok` or `:error`
  end

  # def extract_from(ok_tuples) do
  #   Enum.map(ok_tuples, &elem(&1, 1))
  # end

  def transform(errors) do
    Enum.map(
      errors,
      fn
        ({:error, :entities_reserved, reserved}) ->
          {:entities_reserved, reserved}
        ({:error, %Ecto.Changeset{} = cs}) ->
          {:invalid_changeset, cs}
        # 2019-01-23_0617 NOTE (homogeneous lists)
        # ({:error, changesets} when is_list(changesets)) ->
        #   {:invalid_changesets, changesets}
      end)
  end


  defp generate_changeset(%command{} = command_struct, attrs) do
    command.changeset(command_struct, attrs)
  end

  # See (Evolution of `imbue_command`) NOTEs
  def imbue_command(
    %command{} = command_struct,
    attrs,
    consistency
  ) do
    changeset = command.changeset(command_struct, attrs)
    case changeset.valid? do
      true ->
        # command_with_params = struct(changeset.data, changeset.changes)
        {:ok, Changeset.apply_changes(changeset), consistency}
      false ->
        {:error, changeset}
    end
  end

  # # See (Evolution of `imbue_command`) NOTEs
  # # [command_struct, attrs_map] ->
  # #     {:ok,    [command]}
  # #   | {:error, [command_changeset]}
  # def imbue_commands(
  #   [ {                 %C.RegisterUser{} = r_struct, r_attrs},
  #     {%C.AddUsernamePasswordCredential{},            a_attrs},
  #   ]
  # ) do

  #   make_add_changeset =
  #     fn(user_id) ->
  #       %C.AddUsernamePasswordCredential{user_id: user_id}
  #       |> generate_changeset(a_attrs)
  #     end

  #   r_changeset = generate_changeset(r_struct, r_attrs)

  #   case r_changeset.valid? do

  #     true  ->
  #       r_command   = Changeset.apply_changes(r_changeset)
  #       a_changeset = make_add_changeset.(r_command.user_id)

  #       case a_changeset.valid? do
  #         true  ->
  #           {:ok, [r_command, Changeset.apply_changes(a_changeset)]}
  #         false ->
  #           {:error, [a_changeset]}
  #       end

  #     false ->
  #       # The uuid  is only a placeholder  to return changeset
  #       # validation  errors.  (Remember, returning  :ok  only
  #       # when  both commands  succeed,  therefore this  value
  #       # will always be discarded; we just need the errors!)
  #       a_changeset = make_add_changeset.(Ecto.UUID.generate())

  #       case a_changeset.valid? do
  #         true ->
  #           {:error, [r_changeset]}
  #         false ->
  #           {:error, [r_changeset, a_changeset]}
  #       end
  #   end
  # end

  # # (FP sidenote: this is like an "either", right?

  # # USE CASE: for independent commands
  # # [command_struct, attrs_map] ->
  # #     {:ok,    [command]}
  # #   | {:error, [command_changeset]}
  # def imbue_commands(command_param_tuples) when is_list(command_param_tuples) do

  #   applied_changesets =
  #     Enum.map(
  #       command_param_tuples,
  #       fn({%command{} = command_struct, attrs}) ->
  #         changeset = command.changeset(command_struct, attrs)
  #         case changeset.valid? do
  #           true ->
  #             # command_with_params = struct(changeset.data, changeset.changes)
  #             Changeset.apply_changes(changeset)
  #           false ->
  #             changeset
  #         end
  #       end)

  #   filtered_errors =
  #     Enum.filter(
  #       applied_changesets,
  #       fn
  #         (%Changeset{}) -> true
  #                    (_) -> false
  #       end)

  #   case length(filtered_errors) do
  #     0 -> {:ok, applied_changesets} # i.e., valid commands at this point
  #     _ -> {:error, filtered_errors}
  #   end
  # end

  # 2019-01-24_1437 NOTE

  @doc """
  Convert from one type of struct to another.
  """
  def convert_struct(from, to) do
    # 2019-01-24_1437 NOTE (Jason needed `Map.from_struct/1` -> `from/1` switch)
    struct(to, struct_to_map(from))

    # Because I keep forgettting:
    #
    # iex(2)> defmodule A do
    # ...(2)>   defstruct [:a, :b]
    # ...(2)> end
    #
    # iex(3)> struct(A, %{a: 27})
    # %A{a: 27, b: nil}
    #
    # iex(4)> struct(A, %{a: 27, b: 7, c: 9})
    # %A{a: 27, b: 7}

    # Leaving this for posterity that piping is nice
    # but it can be overdone.
    #
    # from
    # |> Map.from_struct()
    # |> (&struct(to, &1)).()
  end

  # def assign_id(struct, field) do
  #   new_id = Ecto.UUID.generate()
  #   Map.put(struct, field, new_id)
  #   new_id
  # end

  @doc """
  Recursive version of `Map.from_struct/1`
  """
  defp struct_to_map(struct) do
    map = Map.delete(struct, :__struct__)
    map_keys = Map.keys(map)
    Enum.reduce(
      map_keys,
      %{},
      fn(key, acc) ->
        s = Map.get(map, key)
        value =
          case is_map(s) && Map.has_key?(s, :__struct__) do
            true  -> struct_to_map(s)
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
