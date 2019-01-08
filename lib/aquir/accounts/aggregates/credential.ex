defmodule Aquir.Accounts.Aggregates.Credential do
  use Ecto.Schema

  # TODO How to query the state of an aggregate?

  alias Aquir.Accounts.Aggregates.{Commands, Events}
  alias Aquir.Commanded

  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    field :for_user_id,   :binary_id
    field :type,          :string
    # Why is this not `embeds_many/3`? See NOTE 2019-01-07_1650
    field :data,          :map
  end

  ###########
  # EXECUTE #
  ###########

  # See TODO 2019-01-07_2123
  def execute(
    %__MODULE__{credential_id: nil},
    %Commands.AddUsernamePasswordCredential{} = command
  ) do
    Commanded.Support.convert_struct(command,

  # TODO: If the password_hash does not exist then the app shouldn't
  #       even compile. Make it a test?
  def execute(
    %__MODULE__{password_hash: ""},
    %Commands.ResetPassword{}
  ) do
    Logger.error "An existing user should have a password hash"
    raise "An existing user should have a password hash"
  end

  def execute(_user, %Commands.ResetPassword{} = command) do
    Commanded.Support.convert_struct(command, Events.PasswordReset)
  end

  #########
  # APPLY #
  #########

  def apply(user, %Events.PasswordReset{password_hash: new_pwhash}) do
    %__MODULE__{ user | password_hash: new_pwhash }
  end
end
