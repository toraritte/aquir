defmodule Aquir.Accounts.Events.UsernamePasswordCredentialAdded do

  @derive Jason.Encoder
  defstruct [
    :credential_id,
    :for_user_id,
    :type,
    :payload,
  ]
end
