defmodule Aquir.Users.Aggregates.Credential do
  use Ecto.Schema

  alias Aquir.Users.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  # 2019-01-30_0628 NOTE (Credential :type field flip-flop)
  @primary_key false
  embedded_schema do
    field :credential_id, :binary_id
    field :user_id,       :binary_id
    field :type,          :string
    # 2019-01-07_1650 NOTE (What is payload?)
    field :payload,       :map
  end

  # 2019-01-10_0544 QUESTION (Correlation and causation IDs?)
  # 2019-01-10_0604 QUESTION (Event metadata use cases?) (answered)
  # 2019-01-10_0633 QUESTION (How to implement event versioning?)

  ###########
  # EXECUTE #
  ###########

  def execute(
    %__MODULE__{credential_id: nil},
    %Commands.AddUsernamePasswordCredential{} = command
  ) do
    ACS.convert_struct(command, Events.UsernamePasswordCredentialAdded)
  end

  # TODO: If the password_hash does not exist then the app shouldn't
  #       even compile. Make it a test?
  # def execute(
  #   %__MODULE__{password_hash: ""},
  #   %Commands.ResetPassword{}
  # ) do
  #   Logger.error "An existing user should have a password hash"
  #   raise "An existing user should have a password hash"
  # end

  def execute(_user, %Commands.ResetPassword{} = command) do
    ACS.convert_struct(command, Events.PasswordReset)
  end

  ##########
  ## APPLY #
  ##########

  # TODO Define  debug messages for `c.apply/2`  as well
  # in Commanded. See 2019-01-07_2123 for some context
  def apply(
    %__MODULE__{credential_id: nil},
    %Events.UsernamePasswordCredentialAdded{} = event
  ) do
    ACS.convert_struct(event, __MODULE__)
  end

  def apply(
    user,
    %Events.PasswordReset{
      username:      username,
      password_hash: new_pwhash,
    }
  ) do

    payload = %{
      username:      username,
      password_hash: new_pwhash,
    }

    %__MODULE__{ user | payload: payload }
  end
end
