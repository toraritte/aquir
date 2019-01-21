defmodule Aquir.Accounts.Support.Unique do
  use Agent

  alias Aquir.Accounts.Read
  alias Read.Schemas, as: RS

  def start_link(_) do
    Agent.start_link(
      fn ->

        usernames = Read.get_all(:username, RS.Credential)
        emails    = Read.get_all(:email,    RS.User)

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

  def taken?(key, value) do
    is_it? =
      Agent.get(__MODULE__, &value_in_state?(&1, key, value))

    case is_it? do
      true ->
        {:ok, :"#{key}_available", value}
      false ->
        {:error, :"#{key}_already_taken", value}
    end
  end

  # 2019-01-20_1048 TODO (Make generic across contexts)
  # 2019-01-20_1048 TODO DONE (Re-populate on startup)

  def claim(keywords) do
    any_claimed_already? =
      Agent.get_and_update(
        __MODULE__,
        fn(state) ->

          key_statuses =
            keywords
            |> Enum.map(
                 fn({key, value}) ->
                   case value_in_state?(state, key, value) do
                     true ->
                       {:taken, key, value}
                     false ->
                       {:free, key, value}
                   end
                 end)

          keys_taken =
            key_statuses
            |> Enum.filter(fn({status, _, _}) -> status == :taken end)
            |> Enum.map(fn({:taken, key, value}) -> {key, value} end)
              # entites_mapset = Map.get(state, key)

              # case value_in_state?(state, key, value) do
              #   true ->
              #     {true, :already_claimed}
              #   false ->
              #     {false, MapSet.put(entites_mapset, value)}
              # end
            # end)

          case length(keys_taken) do
            0 ->
              new_state =
                keywords # eltenni mindegyiket a megfelelo helyre
              # remember, state is:
              # %{key1: mapset1, key2: mapset2, etc}

              {false, Map.put(state, key, new_entities_mapset)}
            _ ->
              # get, new_state
              {{true, keys_taken}, state}
          end
        end)

    case claimed? do
      {true, keys_taken} ->
        {:error, :keys_already_taken, keys_taken}
      false ->
        {:ok, :claim_successfully, keywords}
    end
  end

  def get_state, do: Agent.get(__MODULE__, &(&1))
end
