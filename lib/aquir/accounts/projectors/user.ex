defmodule Aquir.Accounts.Projectors.User do
  use Commanded.Projections.Ecto,
    name: "Accounts.Projections.User",
    repo: Aquir.Repo,
    consistency: :strong

  # NOTE 2018-10-23_2154
  @doc """
  Where is `:consistency` above defined? Commanded.Projections.Ecto
  has  one file basically (ecto.ex) and it's not in there.
  """

  alias Aquir.Accounts.{
    Events,
    Projections,
    Aggregates,
  }

  @doc """
  The  UserRegistered event  and the  Projections.User
  struct hold the same keys, hence the conversion, and
  Multi.insert/4  takes  data as  well  in  lieu of  a
  changeset. (Which  is unnecessary because  the event
  is  generated from  the  a command  that is  already
  validated using changesets.)
  """
  project %Events.UserRegistered{} = u do
    Ecto.Multi.insert(
      multi,
      :add_user,
      Aggregates.Support.convert_struct(u, Projections.User)
    )
  end

  # NOTE 2018-10-19_2344
  @doc """
  The state of the User  aggregate is fetched from the
  User  projection in  the  database,  but that  state
  should  also be  available  in  the stream  process.
  Aggregate instances (i.e.,  streams) are implemented
  as  GenServers,  therefore,  unless the  system  has
  been restarted/crashed before,  this state should be
  available.

  If the Phoenix server  has been restarted or crashed
  before the Commanded.Aggregates.Supervisor will show
  no spawned process.

  + How  and  when  will   get  the  stream  processes
    respawned  or on  what  condition  after a  system
    restart?

  + Will their events  get re-applyed automatically on
    such  respawn or  do I  need  to bring  back to  a
    consistent state manually re-applying the events?
  """
  project %Events.PasswordReset{} = u do

    case Projections.User.get_user_by_email(u.email) do
      nil ->
        multi
      user ->
        user
        |> Ecto.Changeset.change(password_hash: u.password_hash)
        |> (&Ecto.Multi.update(multi, :reset_password, &1)).()
    end
  end
end
# Aquir.Accounts.register_user(%{"email" => "alvaro@miez.com", "password" => "balabab"})
# Aquir.Accounts.reset_password(%{"email" => "alvaro@miez.com", "password" => "mas"})
