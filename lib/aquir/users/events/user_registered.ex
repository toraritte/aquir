defmodule Aquir.Users.Events.UserRegistered do

  @derive Jason.Encoder

  defstruct [
    :user_id,
    :contact_id,
  ]
end
