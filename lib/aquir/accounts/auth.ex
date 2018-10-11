defmodule Aquir.Accounts.Auth do

  alias Comeonin.Bcrypt

  def hash_password(password),     do: Bcrypt.hashpwsalt(password)
  def validate_password(password), do: Bcrypt.checkpw(password, hash)
end
