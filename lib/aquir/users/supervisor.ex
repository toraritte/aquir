defmodule Aquir.Users.Supervisor do
  use Supervisor

  alias Aquir.Users

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do

    children = [
      Users.Read.Projector,
      Users.Unique,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
