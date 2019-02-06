defmodule Aquir.Contacts.Events.ContactAdded do

  @derive Jason.Encoder

  defstruct [
    :contact_id,
    :first_name,
    :middle_name,
    :last_name,
  ]
end
