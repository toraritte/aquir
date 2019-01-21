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

  def show(conn, %{"username" => username}) do

    user =
      Accounts.Read.get_user_by(username: username)
      |> unwrap_credentials_in_user()

    render(conn, "show.html", user: user)
  end

  defp unwrap_credentials_in_user(user_with_credentials) do
    cs = user_with_credentials.credentials
    Map.put(user_with_credentials, :credentials, hd(cs))
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # 2019-01-18_1312 NOTE
  @doc """
  The form (`new.html.eex`) only  asks for name, email
  address  and  password,  because at  this  time  the
  username is  extracted from  the email  address (see
  `user_params_with_username`). This  can be  easily modified
  because  `Accounts.register_user/1`  would accept  a
  username as well.
  """
  def create(conn, %{"user" => user}) do

    case Accounts.register_user(user) do
      {:ok, user_with_credentials} ->

        user = unwrap_credentials_in_user(user_with_credentials)
        username = user.credentials.username

        conn
        |> put_flash(:info, "#{username} created!")
        |> redirect(to: user_path(conn, :show, username))

      # {:error, [changeset_1, ..., changeset_N]}
      {:error, :username_already_taken = error, username} ->
        error_text = Phoenix.HTML.Form.humanize(error) <> ": #{username}"
        render(conn, "new.html", errors: [error_text])

      # {:error, :username_already_in_database, username} ->
      # {:error, :email_already_in_database, email} ->

      # {:error, changesets_list} ->
      {:error, error} ->
        render(conn, "new.html", errors: [error])
    end
  end

  defp render_error(path, error, entity) when is_atom(error) do
    error_text = Phoenix.HTML.Form.humanize(error) <> ": #{entity}"
    render(conn, path, errors: [error_text])
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
