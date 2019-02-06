defmodule Aquir.Contacts.Events.EmailAdded do

  @derive Jason.Encoder

  defstruct [
    :email_id,
    :contact_id,
    :email,
    :type,
  ]
end
