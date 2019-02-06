defmodule Aquir.Contacts.Aggregates.Email do
  use Ecto.Schema

  alias Aquir.Contacts.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  @primary_key false
  embedded_schema do
    field :email_id,   :binary_id
    field :contact_id, :binary_id
    field :email,      :string
    field :type,       :string # work, personal, ?
  end




  ###########
  # EXECUTE #
  ###########

  # 2019-01-07_2123 NOTE (Why checking for `user_id: nil`?)
  def execute(
    %__MODULE__{email_id: nil},
    %Commands.AddEmail{} = command
  ) do
    ACS.convert_struct(command, Events.EmailAdded)
  end

  #########
  # APPLY #
  #########

  def apply(%__MODULE__{email_id: nil}, %Events.EmailAdded{} = event) do
    # Simply converting the event to %User{} because there
    # is no state before registering.
    ACS.convert_struct(event, __MODULE__)
  end
end
