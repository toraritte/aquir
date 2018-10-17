defmodule Aquir.Accounts.Projectors.User do
  use Commanded.Projections.Ecto,
    name: "Accounts.Projections.User",
    consistency: :strong

  alias Aquir.Accounts.Events.{
    UserRegistered,
    PasswordReset,
  }
  alias Aquir.Accounts.Projections.User

  project %UserRegistered{} = u do
    Ecto.Multi.insert(multi, :add_user, %User{
      uuid:          u.user_uuid,
      email:         u.email,
      password_hash: u.password_hash,
    })
  end

  project %PasswordReset{} = u do
    Ecto.Multi.update(multi, :reset_password, %User{
      password_hash: u.password_hash
    })
  end
end
