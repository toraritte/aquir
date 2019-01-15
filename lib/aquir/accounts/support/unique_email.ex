defmodule Aquir.Accounts.Support.UniqueUsername do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  def claim(name) do
    name_is_taken = Agent.get(__MODULE__, &MapSet.member?(&1, name))

    case name_is_taken do
      false ->
        # `cast/2` would probably be  enough because a process
        # is sequential internally, but  it is prudent to make
        # sure  and  wait  for  an `:ok`  to  make  sure  that
        # username  is  saved. For  a  larger  service a  more
        # robust key-value store would be a better option.
        Agent.update(__MODULE__, &MapSet.put(&1, name))
        :ok
      true  ->
        {:error, :username_already_taken}
    end
  end
end
