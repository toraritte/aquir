defmodule Aquir.Unique do
  use Agent

  alias Aquir.Commanded.Read, as: ACRead

  alias Aquir.{
    Users,
    Contacts
  }
  alias    Users.Read.Schemas, as: URS
  alias Contacts.Read.Schemas, as: CRS

  @moduledoc """
  The   `Unique`   agent's   state  is   set   up   at
  compile-time,   statically   at    the   moment   in
  `Unique.start_link/1`.  The field  keys are  fetched
  from the read model, but  it still works if the read
  model  is  empty,  because `Repo.all/?`  returns  an
  empty  list  in this  case,  and  `MapSet`s will  be
  initialized with these.

  Current entities:

  + `:email`
  + `:username`

  The data structure holding the state:  
  `%{ key_1: mapset(values), ..., :key_N: mapset(values)}`

  Previous  version of  `claim/1`  allowed adding  new
  keys  (see  commit  53bb32e  and  before,  unless  I
  overwrote the history (again...)), but that wouldn't
  be  prudent: the  application  has to  know its  own
  entities. (Unless  there comes  a feature  idea that
  needs this agent's state to be dynamic.)
  """

  def start_link(_) do
    Agent.start_link(
      fn ->

        # These result in empty lists if read model is empty.
        usernames = ACRead.get_all_entity(URS.UsernamePasswordCredential, :username)
        emails    = ACRead.get_all_entity(CRS.Email, :email)

        %{
          username: MapSet.new(usernames),
          email:    MapSet.new(emails),
         }
      end,
      name: __MODULE__
    )
  end

  defp value_in_state?(state, key, value) do
    state
    |> Map.get(key)
    |> MapSet.member?(value)
  end

  defp free?(_state, []), do: true

  defp free?(state, keywords) do

    reserved =
      Enum.reduce(
        keywords,
        [],
        fn({key, value} = kv_tuple, acc) ->
          case value_in_state?(state, key, value) do
            true  -> [kv_tuple | acc]
            false -> acc
          end
        end)

    case length(reserved) do
      0 -> true
      _ -> {false, reserved}
    end
  end

  # just a wrapper around `free?/1`
  def check(keywords) do
    case free?(get_state(), keywords) do
      true              -> {:ok, :entities_free, keywords}
      {false, reserved} -> entities_reserved_error(reserved)
    end
  end

  # 2019-01-20_1048 TODO DONE (Re-populate on startup)
  # 2019-01-20_1048 TODO (Make generic across contexts)

  def claim(keywords) do

    all_free? =
      Agent.get_and_update(
        __MODULE__,
        fn(state) ->
          # has to be checked here to make updates atomic
          case free?(state, keywords) do
            true ->
              new_state = update_state_mapsets(state, keywords)
              # get, new_state
              {true, new_state}
            {false, reserved} ->
              # get, new_state
              {{false, reserved}, state}
          end
        end)

    case all_free? do
      true              -> {:ok, :claim_successful, keywords}
      {false, reserved} -> entities_reserved_error(reserved)
    end
  end

  defp entities_reserved_error(keywords) do
    {:error, :entities_reserved, keywords}
  end

  defp update_state_mapsets(state, keywords) do
    # 2019-01-25_0851 NOTE (Why `reduce` and some explanation)
    Enum.reduce(keywords, state, fn({key, value}, state_acc) ->
      Map.update!(state_acc, key, &MapSet.put(&1, value))
    end)
  end

  def get_state, do: Agent.get(__MODULE__, &(&1))
end
