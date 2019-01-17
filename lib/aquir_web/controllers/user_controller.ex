defmodule AquirWeb.UserController do
  use AquirWeb, :controller

  alias Aquir.Accounts

  action_fallback AquirWeb.FallbackController

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      users: transform_userlist_with_credentials()
    )
  end

  @doc """
  Turns `Aquir.Accounts.list_users_with_credentials/0`'s
  output, such as

  ```elixir
  [
    %Aquir.Accounts.Read.Schemas.User{
      __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
      credentials: [
        %Aquir.Accounts.Read.Schemas.Credential{
          __meta__: #Ecto.Schema.Metadata<:loaded, "users_credentials">,
          credential_id: "00f0897e-b2e6-4125-ae77-bcec4618df67",
          for_user_id: "8df55399-3dec-4ae2-973c-593ee60edb7c",
          inserted_at: ~N[2019-01-16 15:14:50],
          password_hash: "$2b$12$Q2rwTn4juwqn5G7kB.oTV.L3aDU.rvXZ6MhaVPA5lHeUdFDqv1QWa",
          type: "username_password",
          updated_at: ~N[2019-01-16 15:14:50],
          user: #Ecto.Association.NotLoaded<association :user is not loaded>,
          username: "hh"
        }
      ],
      email: "@h",
      inserted_at: ~N[2019-01-16 15:14:50],
      name: "h",
      updated_at: ~N[2019-01-16 15:14:50],
      user_id: "8df55399-3dec-4ae2-973c-593ee60edb7c"
    },
    # ...
  ]
  ```

  into

  ```elixir
  [
    %{
      email: "@a",
      name: "a",
      user_id: "32205242-36c9-438c-b198-f5cb89348593",
      username: "aa"
    },
    # ...
  ]
  ```
  """
  defp transform_userlist_with_credentials do
    Enum.map(
      Accounts.list_users_with_credentials(),
      fn(user_with_credentials) ->
        Enum.reduce(
          Map.keys(user_with_credentials),
          %{},
          fn
            (:credentials, acc) ->

              username_password_credential =
                Enum.find(
                  user_with_credentials.credentials,
                  fn(credential) -> credential.type == "username_password" end)

              Map.put(acc, :username, username_password_credential.username)

            (key, acc) when key in [:user_id, :email, :name] ->
              Map.put(acc, key, Map.get(user_with_credentials, key))

            (_, acc) ->
              acc
          end)
      end)
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # def index(conn, _params) do
  #   users = Accounts.list_users()
  #   render(conn, "index.json", users: users)
  # end

  # def create(conn, %{"user" => user_params}) do
  #   with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
  #     conn
  #     |> put_status(:created)
  #     # |> put_resp_header("location", user_path(conn, :show, user))
  #     |> render("show.json", user: user)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   user = Accounts.get_user!(id)
  #   render(conn, "show.json", user: user)
  # end

  # def update(conn, %{"id" => id, "user" => user_params}) do
  #   user = Accounts.get_user!(id)

  #   with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
  #     render(conn, "show.json", user: user)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   user = Accounts.get_user!(id)
  #   with {:ok, %User{}} <- Accounts.delete_user(user) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
