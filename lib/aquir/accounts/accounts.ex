defmodule Aquir.Accounts do
  use Aquir.Commanded.ContextWrapper, [Aquir.Accounts.Read, Aquir.Accounts.Write]
end
