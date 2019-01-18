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
      Accounts.Read.list_users_with_credentials(),
      &unwrap_credentials_in_user/1)
  end

  defp unwrap_credentials_in_user(user_with_credentials) do
    cs = user_with_credentials.credentials
    Map.put(user_with_credentials, :credentials, hd(cs))
  end

  def show(conn, %{"user_id" => user_id}) do

    user =
      Accounts.Read.get_user_by_id(user_id)
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

  @doc """
  The form (`new.html.eex`) only  asks for name, email
  address  and  password,  because at  this  time  the
  username is  extracted from  the email  address (see
  `user_with_username`). This  can be  easily modified
  because  `Accounts.register_user/1`  would accept  a
  username as well.
  """
  def create(conn, %{"user" => user}) do
    # require IEx; IEx.pry

    user_with_username =
      user["email"]
      |> String.split("@")
      |> hd()
      |> (&Map.put(user, "username", &1)).()

    {:ok, user} = Accounts.register_user(user_with_username)

    conn
    |> put_flash(:info, "#{user.name} created!")
    |> redirect(to: user_path(conn, :index))
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
