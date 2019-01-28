defmodule Aquir.Accounts.Events.UsernamePasswordCredentialAdded do

  @derive Jason.Encoder
  defstruct [
    :credential_id,
    :user_id,
    :type,
    :payload,
  ]
end
