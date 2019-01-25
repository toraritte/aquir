defmodule AquirWeb.Auth do
  use AquirWeb, :controller

  alias Aquir.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.Read.get_user_by(user_id)
    assign(conn, :current_user, user)
  end

  def authenticate(conn) do
    case conn.assigns.current_user do

      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()

      %Accounts.Read.Schemas.User{} ->
        conn
    end
  end
end
