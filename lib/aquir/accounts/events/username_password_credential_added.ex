defmodule Aquir.Accounts.Events.UsernamePasswordCredentialAdded do

  @derive Poison.Encoder
  defstruct [
    :credential_id,
    :for_user_id,
    :type,
    :data,
  ]
end
