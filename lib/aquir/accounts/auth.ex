defmodule Aquir.Accounts.Auth do

  import Ecto.Changeset
  alias Aquir.Accounts.Read
  alias Read.Schemas, as: RS

  defp hash_password(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end

  defp validate_password(password, hash) do
    Comeonin.Bcrypt.checkpw(password, hash)
  end

  def secure_password(
    %Ecto.Changeset{valid?: true, changes: changes} = changeset,
    password_field
  ) do
      pw = changes[password_field]

      changeset
      |> put_change(:password_hash, hash_password(pw))
      |> put_change(password_field, nil)
  end
  # changeset is invalid
  def secure_password(changeset, _), do: changeset

  # 2019-01-29_0603 TODO (Strengthen password checks)
  def authenticate_by_username_and_password(username, given_pass) do
    Read.get_by(RS.UsernamePasswordCredential, username: username)
    |> Comeonin.Bcrypt.check_pass(given_pass)
    # {:ok, user}
    # {:error, message}
  end
end
