defmodule Aquir.Users.Events.UserRegistered do

  @derive Jason.Encoder

  defstruct [
    :user_id,
    :name,
    :email,
  ]
end
