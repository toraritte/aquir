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

  defp transform_userlist_with_credentials do
    Enum.map(
      Accounts.list_users_with_credentials(),
      &unwrap_credentials_in_user/1)
  end

  def unwrap_credentials_in_user(user_with_credentials) do
    cs = user_with_credentials.credentials
    Map.put(user_with_credentials, :credentials, hd(cs))
  end

  def show(conn, %{"user_id" => user_id}) do

    user =
      Accounts.get_user_by_id(user_id)
      |> unwrap_credentials_in_user()

    render(
      conn,
      "show.html",
      user: user
    )
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
