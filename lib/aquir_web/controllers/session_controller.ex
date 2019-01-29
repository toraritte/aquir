defmodule AquirWeb.SessionController do
  use AquirWeb, :controller

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(
    conn,
    %{"session" => %{"username" => username, "password" => given_pass}}
  ) do

    login? =
      AquirWeb.Auth.login_by_username_and_password(conn, username, given_pass)

    # require IEx; IEx.pry
    case login? do
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render("new.html")
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def delete(conn, _) do
    conn
    |> AquirWeb.Auth.logout()
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
