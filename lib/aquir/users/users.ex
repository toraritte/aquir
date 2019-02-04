defmodule Aquir.Users do
  # 2019-02-04_1509 TODO (make this `use Wrapper, context: Users
  use Aquir.Commanded.ContextWrapper, [Aquir.Users.Read, Aquir.Users.Write]
end
