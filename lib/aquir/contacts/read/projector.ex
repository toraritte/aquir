defmodule Aquir.Contacts.Read.Projector do
  use Commanded.Projections.Ecto,
    name: "Aquir.Contacts",
    repo: Aquir.Repo,
    consistency: :strong

  alias Aquir.Contacts.Read
  alias Read.Schemas, as: RS

  alias Aquir.Contacts.Events
  alias Aquir.Commanded.Support, as: ACS

  project %Events.ContactAdded{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :add_new_contact,
        ACS.convert_struct(event, RS.Contact)
      )
    end

  # 2019-01-30_0628 NOTE (Credential :type field flip-flop)
  project %Events.EmailAdded{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :add_new_email,
        ACS.convert_struct(event, RS.Email)
      )
    end
end
