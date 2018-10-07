defmodule Aquir.Accounts.Supervisor do
  use Supervisor

  alias Aquir.Accounts.{
    Projectors,
    Support,
  }

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do

    children = [
      Projectors.User,
      Support.UniqueUsername,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
