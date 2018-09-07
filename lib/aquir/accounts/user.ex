defmodule Aquir.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "accounts_users" do
    field :email, :string
    field :hashed_password, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :hashed_password])
    |> validate_required([:username, :email, :hashed_password])
  end
end
