defmodule Aquir.Accounts.Read do

  import Ecto.Query

  alias Aquir.Repo
  alias __MODULE__.Schemas, as: RS

  # alias __MODULE__.Schemas, as: RS

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
  # INTERNAL TO ACCOUNTS
  # --------------------
  def get(schema, entity_key, entity) do

    query = from e in schema,
              where: field(e, ^entity_key) == ^entity

    Repo.one(query)
  end

  def check_dup(schema, entity_key, entity) do
    case    get(schema, entity_key, entity) do
      nil -> :ok
      _   -> {:error, :"#{entity_key}_already_in_database", entity}
    end
  end

  def get_all(field, schema) do
    from(e in schema, select: field(e, ^field))
    |> Aquir.Repo.all()
  end


  # EXTERNAL TO ACCOUNTS
  # --------------------
  defp all_users_with_credentials_query do
      from u in RS.User,
        join: c in RS.Credential,
        on: u.user_id == c.for_user_id,
        preload: [credentials: c]
  end

  def list_users_with_credentials do
    Repo.all all_users_with_credentials_query()
  end

  def get_user_by(user_id: user_id) do
    from(
      [u,c] in all_users_with_credentials_query(),
      where: u.user_id == ^user_id)
    |> Repo.one()
  end

  def get_user_by(username: username) do
    from(
      [u,c] in all_users_with_credentials_query(),
      where: c.username == ^username)
    |> Repo.one()
  end
end
# iex(4)> defmodule A do
# ...(4)>   defmacro error!(args) do
# ...(4)>     quote do
# ...(4)>       _ = unquote(args)
# ...(4)> 
# ...(4)>       message =
# ...(4)>         "Elixir's special forms are expanded by the compiler and must not be invoked dir
# ectly"
# ...(4)> 
# ...(4)>       :erlang.error(RuntimeError.exception(message))
# ...(4)>     end
# ...(4)>   end
# ...(4)>   defmacro with(args), do: error!([args])
# ...(4)> end
