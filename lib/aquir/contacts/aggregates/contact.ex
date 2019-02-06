defmodule Aquir.Contacts.Aggregates.Contact do
  use Ecto.Schema

  alias Aquir.Contacts.{Commands, Events}
  alias Aquir.Commanded.Support, as: ACS

  @primary_key false
  embedded_schema do
    field :contact_id,  :binary_id
    field :first_name,  :string
    field :middle_name, :string
    field :last_name,   :string
    field :birth_date,  :date
    field :death_date,  :date
  end


  ###########
  # EXECUTE #
  ###########

  # 2019-01-07_2123 NOTE (Why checking for `user_id: nil`?)
  def execute(
    %__MODULE__{contact_id: nil},
    %Commands.AddContact{} = command
  ) do
    ACS.convert_struct(command, Events.ContactAdded)
  end

  #########
  # APPLY #
  #########

  def apply(%__MODULE__{contact_id: nil}, %Events.ContactAdded{} = event) do
    # Simply converting the event to %User{} because there
    # is no state before registering.
    ACS.convert_struct(event, __MODULE__)
  end
end
