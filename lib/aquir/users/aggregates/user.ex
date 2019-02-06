defmodule Aquir.Users.Aggregates.User do
  use Ecto.Schema

  alias Aquir.Users.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  # 2019-01-16_0804 TODO (stream lifespan)
  # 2019-02-05_0803 NOTE (Why keep User aggregate? Why not just convert Credential?)

  @primary_key false
  embedded_schema do
    field :user_id,    :binary_id
    field :contact_id, :binary_id

    # See NOTE 2019-01-06_1938 on the missing `embeds_many/3` for credentials
  end

  ###########
  # EXECUTE #
  ###########

  # 2019-01-07_2123 NOTE (Why checking for `user_id: nil`?)
  def execute(
    %__MODULE__{user_id: nil},
    %Commands.RegisterUser{} = command
  ) do
    ACS.convert_struct(command, Events.UserRegistered)
  end

  #########
  # APPLY #
  #########

  # `User` aggregate state:
  # %Aquir.Users.Aggregates.User{email: nil, name: nil, user_id: nil}
  def apply(%__MODULE__{user_id: nil}, %Events.UserRegistered{} = event) do
    # Simply converting the event to %User{} because there
    # is no state before registering.
    ACS.convert_struct(event, __MODULE__)
  end
end
