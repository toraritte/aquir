defmodule Aquir.Accounts.Supervisor do
  use Supervisor

  alias Aquir.Accounts, as: A

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do

    children = [
      A.Read.Projector,
      A.Support.UniqueEmail,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
