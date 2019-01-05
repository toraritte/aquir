defmodule Aquir.Accounts.Aggregates.Credential do
  use Ecto.Schema

  embedded_schema do
    field :credential_id, :binary_id
    field :for_user_id,   :binary_id
    field :type,          :string
    field :data,          :map
  end
end
