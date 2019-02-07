defmodule Aquir.Users do
  @external_resource "./lib/aquir/users/read.ex"
  @external_resource "./lib/aquir/users/write.ex"
  @external_resource "./lib/aquir/users/auth.ex"
  # 2019-02-04_1509 TODO (make this `use Wrapper, context: Users
  use(
    Aquir.Commanded.ContextWrapper,
    [ Aquir.Users.Read,
      Aquir.Users.Write,
      Aquir.Users.Auth,
    ]
  )
end
