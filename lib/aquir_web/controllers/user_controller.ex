defmodule AquirWeb.UserController do
  use AquirWeb, :controller

  alias Aquir.Users

  # See 2019-02-07_0944 NOTE as to why this is here
  # plug AquirWeb.Auth, :authorize_user_if_signed_in when action in [:index, :show, :new]

  action_fallback AquirWeb.FallbackController

  # 2019-01-30_0448 NOTE (Controller action definition)
  # def action(conn, _) do
  #   args = [conn, conn.params]
  #   apply(__MODULE__, action_name(conn), args)
  # end

  def index(conn, _params) do
    # case AquirWeb.Auth.authenticate(conn) do
    #   %Plug.Conn{halted: true} ->
    #     conn
    #   conn ->
        users = Users.list_users_with_username_password_credential()
        render(conn, "index.html", users: users)
    # end
  end

  def show(conn, %{"username" => username}) do
    render(
      conn,
      "show.html",
      user: Users.get_user_with_username_password_credential_by(username: username)
    )
  end

  def new(conn, _params) do
    render(conn, "new-from-existing.html")
    # render(conn, "new.html")
  end

  def create(conn, %{"user" => user}) do

    with(
      {:ok, user_with_username_password_credential} <- Users.register_user(user)
    ) do
      username = AquirWeb.UserView.username(user_with_username_password_credential)

      conn
      # |> AquirWeb.Auth.login(user_with_username_password_credential)
      |> put_flash(:info, "User #{username} created!")
      # 2019-01-25_1547 QUESTION (Adding 201 and Location does weird stuff)
      |> redirect(to: Routes.user_path(conn, :show, username))

    else
      {:errors, errors} ->
        conn
        |> put_status(:bad_request)
        |> render("new.html", errors: Users.parse_errors(errors))
    end
  end

  # def rec_map_to_list(nested_maps) do

  #   mlist = Map.to_list(nested_maps)

  #   Enum.map(
  #     Keyword.keys(mlist),
  #     fn(key) ->
  #       {
  #         key,
  #         case mlist[key] do
  #           next_map when is_map(next_map) ->
  #             rec_map_to_list(next_map)
  #           value -> value
  #         end
  #       }
  #   end)
  # end

  # def index(conn, _params) do
  #   users = Users.list_users()
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
