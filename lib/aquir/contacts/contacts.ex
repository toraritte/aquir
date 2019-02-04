defmodule Aquir.Contacts do
  use Aquir.Commanded.ContextWrapper, [Aquir.Contacts.Read, Aquir.Contacts.Write]
end
