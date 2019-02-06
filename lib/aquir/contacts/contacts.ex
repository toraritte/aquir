defmodule Aquir.Contacts do

  # 2019-02-06_1106 NOTE (Why the `@external_resource`s)
  @external_resource "./lib/aquir/contacts/read.ex"
  @external_resource "./lib/aquir/contacts/write.ex"
  use Aquir.Commanded.ContextWrapper, [Aquir.Contacts.Read, Aquir.Contacts.Write]
end
