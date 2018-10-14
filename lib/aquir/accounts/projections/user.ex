defmodule Aquir.Accounts.Projections.User do
  use Ecto.Schema

  alias Aquir.Repo
  import Ecto.Query

  @primary_key {:uuid, :binary_id, autogenerate: false}

  schema "accounts_users" do
    field :username, :string, unique: true
    field :email, :string, unique: true
    field :hashed_password, :string

    timestamps()
  end

  # It may seem redundant that there is a unique constraint on the username in the schema definition above, and `check_username` does the same by manually checking any existing ones. (Not to mention `UniqueUsername.claim/1`). The reason is that a DB constraint never hurts, but the rest is to catch any duplicate usernames **before** an event could be created. If that happens, the system will keep crashing because of the unique DB constraint, but Commanded will dutifully try to apply the event anyway. This could be caught using the `error/3` callback (see https://github.com/commanded/commanded-ecto-projections#error3-callback or https://github.com/commanded/commanded/blob/master/guides/Events.md#error3-callback ), but the faulty events would just accumulate and the event store should never be edited. Hence the workaround in the account context (`account.ex`).
  def check_username(username) do
    from(u in __MODULE__, where: u.username == ^username)
    |> Repo.one()
    |> case do
        nil -> {:ok, "username is free"}
        _   -> {:error, :username_already_in_database}
      end
  end

  def get(uuid) do
    case Repo.get(__MODULE__, uuid) do
      nil        -> {:error, :not_found}
      projection -> {:ok, projection}
    end
  end
end
