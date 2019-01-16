defmodule Aquir.Accounts.Read do
  import Ecto.Query

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
  def get(schema, entity_key, entity) do

    query = from e in schema,
              where: field(e, ^entity_key) == ^entity

    Aquir.Repo.one(query)
  end

  def check_dup(schema, entity_key, entity) do
    case    get(schema, entity_key, entity) do
      nil -> :ok
      _   -> {:error, [:"#{entity_key}_already_in_database", entity]}
    end
  end

  # def get_user_by_id(user_id) do
  #   Aquir.Repo.get(__MODULE__, user_id)
  # end

  # def get_user_by_email(email) do
  #   Aquir.Repo.get_by(__MODULE__, email: email)
  # end
end
