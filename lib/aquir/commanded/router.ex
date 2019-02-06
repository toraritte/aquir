defmodule Aquir.Commanded.Router do
  use Commanded.Commands.CompositeRouter

  router    Aquir.Users.Router
  router Aquir.Contacts.Router
end
