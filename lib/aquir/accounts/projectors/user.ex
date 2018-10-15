defmodule Aquir.Accounts.Projectors.User do
  use Commanded.Projections.Ecto,
    name: "Accounts.Projections.User",
    consistency: :strong

  alias Aquir.Accounts.Events.UserRegistered
  alias Aquir.Accounts.Projections.User

  project %UserRegistered{} = u do
    Ecto.Multi.insert(multi, :user, %User{
      uuid: u.user_uuid,
      email: u.email,
      hashed_password: u.hashed_password
    })
  end
end
