defmodule Aquir.Users.Events.UserAdded do

  @derive Jason.Encoder

  defstruct [
    :user_id,
    :contact_id,
  ]
end
