defmodule Aquir.Accounts.Projections.User do
  use Ecto.Schema

  import Ecto.Query

  @primary_key {:user_id, :binary_id, autogenerate: false}

  schema "accounts_users" do
    field :email, :string, unique: true
    field :password_hash, :string

    timestamps()
  end

  @doc """
  It  may  seem  redundant  that  there  is  a  unique
  constraint  on the  email in  the schema  definition
  above, and  `check_email` does the same  by manually
  checking   any  existing   ones.  (Not   to  mention
  `UniqueEmail.claim/1`).  The  reason  is that  a  DB
  constraint  never hurts,  but the  rest is  to catch
  any duplicate  emails **before**  an event  could be
  created.  If  that  happens, the  system  will  keep
  crashing because  of the  unique DB  constraint, but
  Commanded  will dutifully  try  to  apply the  event
  anyway.  This could  be caught  using the  `error/3`
  callback (see https://github.com/commanded/commanded-ecto-projections#error3-callback
  or https://github.com/commanded/commanded/blob/master/guides/Events.md#error3-callback )
  , but  the faulty  events would just  accumulate and
  the event  store should  never be edited.  Hence the
  workaround in the account context (`account.ex`).
  """
  def check_email(email) do
    from(u in __MODULE__, where: u.email == ^email)
    |> Aquir.Repo.one()
    |> case do
        nil -> :ok
        _   -> {:error, :email_already_in_database}
      end
  end

  def get_user_by_id(user_id) do
    Aquir.Repo.get(__MODULE__, user_id)
  end

  def get_user_by_email(email) do
    Aquir.Repo.get_by(__MODULE__, email: email)
  end
end
