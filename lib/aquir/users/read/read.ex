defmodule Aquir.Users.Read do

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

  # 2019-01-29_1617 NOTE (`preload` works both ways and works on lists too!)
  # 2019-01-30_0516 NOTE (When to use `Repo` bang (!) functions)
  # 2019-01-31_0754 NOTE (Why `Read` is called outside this context?)

  # INTERNAL TO USERS
  # --------------------
  # def generic_match_query(schema, entity_key, entity) do
  #   from(e in schema, where: field(e, ^entity_key) == ^entity)
  # end

  def get_by(schema, keywords) do
    Repo.get_by(schema, keywords)
  end

  def check_dup(schema, [{entity_key, entity}] = keyword) do
    case get_by(schema, keyword) do
      nil -> :ok
      _   -> {:error, :"#{entity_key}_already_in_database", entity}
    end
  end

  def get_all_entity(schema, field) do
    from(e in schema, select: field(e, ^field))
    |> Aquir.Repo.all()
  end

  # EXTERNAL TO USERS
  # --------------------

  # def get_user_by(username: username) do
  #   get_one(RS.User, :username, username)
  # end

  # def get_user_by(user_id: user_id) do
  #   get_one(RS.User, :user_id, user_id)
  # end

  # 2019-01-29_1648 NOTE (Why not re-write these with `preload/2`?)

  defp all_users_with_username_password_credential_query do
      from u in RS.User,
        join: c in RS.UsernamePasswordCredential,
        on: u.user_id == c.user_id,
        preload: [credential: c]
  end

  def list_users_with_username_password_credential do
    Repo.all all_users_with_username_password_credential_query()
  end

  # def get_user_with_username_password_credential_by([{entity, value}]) when is_atom(entity) do

  #   from( q in all_users_with_username_password_credentials_query(),
  #     where: field(q, ^entity) == ^value)
  #   |> Repo.one()
  # end

  def get_user_with_username_password_credential_by(user_id: user_id) do
    from(
      [u,c] in all_users_with_username_password_credential_query(),
      where: u.user_id == ^user_id)
    |> Repo.one()
  end

  def get_user_with_username_password_credential_by(username: username) do
    from(
      [u,c] in all_users_with_username_password_credential_query(),
      where: c.username == ^username)
    |> Repo.one()
  end
end

# IO.inspect(Process.info(self(), :current_stacktrace))
# require IEx; IEx.pry

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
