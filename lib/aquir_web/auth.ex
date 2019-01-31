defmodule AquirWeb.Auth do
  use AquirWeb, :controller

  alias Aquir.Accounts
  alias Accounts.Read
  alias Read.Schemas, as: RS

  # 2019-01-29_1157 TODO (Look at  wwwtech.de's remember_me and current_user plug)
  # 2019-01-29_1200 TODO (How to set cookie max_age and expire properties?)
  def init(opts), do: opts

  def call(conn, opts) do
    apply(__MODULE__, opts, [conn])
  end

  def assign_user_session(conn) do
    user_id = get_session(conn, :user_id)
    user = user_id && Read.get_user_with_username_password_credential_by(user_id: user_id)
    assign(conn, :current_user, user)
  end

  def authenticate_user(conn) do
    case conn.assigns.current_user do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()

      %RS.User{} ->
        conn
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.user_id)
    |> configure_session(renew: true)
  end

  # 2019-01-29_0816 QUESTION (Use cases to keep the session after a logout?)
  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def login_by_username_and_password(conn, username, given_pass) do
    authed? =
      Accounts.Auth.authenticate_by_username_and_password(
        username,
        given_pass
      )
    case authed? do
      {:ok,    user}   -> {:ok, login(conn, user)}
      {:error, reason} -> {:error, reason, conn}
    end
  end
end
