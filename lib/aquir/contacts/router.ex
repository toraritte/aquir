defmodule Aquir.Contacts.Router do
  use Commanded.Commands.Router

  # 2019-01-18_0455 TODO (Add Commanded middlewares)

  alias Aquir.Contacts.Aggregates, as: A
  alias Aquir.Contacts.Commands,   as: C

  dispatch [C.AddContact],
    to: A.Contact,
    identity: :contact_id

  dispatch [
    C.AddEmail,
    ],
    to: A.Email,
    identity: :email_id
end
