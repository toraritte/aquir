defmodule Aquir.Accounts.Events.PasswordReset do

  # 2019-01-15_1021 TODO QUESTION
  @doc """
  TODO
  ====
  Put  useful   info  in   event  metadata,   such  as
  `:credential_id`, who issued this etc.

  See Stackoverflow thread:
  https://stackoverflow.com/questions/32205585/

  QUESTION
  ========
  How to write to event metadata?
  """
  @derive Poison.Encoder
  defstruct [
    # Why the `:credential_id`? See 2019-01-15_1223
    :credential_id,
    :username,
    :password_hash,
  ]
end
