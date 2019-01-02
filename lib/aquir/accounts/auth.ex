defmodule Aquir.Accounts.Auth do

  import Ecto.Changeset

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

end
