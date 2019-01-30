defmodule Aquir.Accounts.Events.UsernamePasswordCredentialAdded do

  # 2019-01-30_0628 NOTE (Credential :type field flip-flop)

  @derive Jason.Encoder
  defstruct [
    :credential_id,
    :user_id,
    :payload,
  ]
end
