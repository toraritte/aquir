defmodule Aquir.Clients do
  use Aquir.Commanded.ContextWrapper, [Aquir.Clients.Read, Aquir.Clients.Write]
end
