defmodule Aquir.Users.Aggregates.User do
  use Ecto.Schema

  alias Aquir.Users.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  # 2019_01-16_0804 TODO
  # Think  about  stream  lifespan (Commanded  calls  it
  # "aggregate  lifespan"  but  it  is  about  aggregate
  # instance processes so ...)
  # https://github.com/commanded/commanded/blob/master/guides/Commands.md#aggregate-lifespan
  @primary_key false
  embedded_schema do
    field :user_id, :binary_id
    field :name,    :string
    field :email,   :string
    # TODO see the papers for more

    # See NOTE 2019-01-06_1938 on the missing `embeds_many/3`
  end

  ###########
  # EXECUTE #
  ###########

  # Why checking for `user_id: nil`? See 2019-01-07_2123
  def execute(
    %__MODULE__{user_id: nil},
    %Commands.RegisterUser{} = command
  ) do
    # IO.puts("\n\n")
    # IO.inspect(user)
    # IO.puts("\n\n")
    ACS.convert_struct(command, Events.UserRegistered)
  end

  #########
  # APPLY #
  #########

  # `User` aggregate state:
  # %Aquir.Users.Aggregates.User{email: nil, name: nil, user_id: nil}
  def apply(%__MODULE__{user_id: nil}, %Events.UserRegistered{} = event) do
    # IO.puts("\n\n")
    # IO.inspect(user)
    # IO.puts("\n\n")
    # Simply converting the event to %User{} because there
    # is no state before registering.
    ACS.convert_struct(event, __MODULE__)
  end
end