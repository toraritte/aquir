defmodule Aquir.Accounts.Support.UniqueUsername do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  def claim(name) do
    name_is_taken = Agent.get(__MODULE__, &MapSet.member?(&1, name))

    case name_is_taken do
      false ->
        Agent.update(__MODULE__, &MapSet.put(&1, name))
        {:ok, :username_claimed}
      true  ->
        {:error, :username_already_taken}
    end
  end
end
