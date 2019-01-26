defmodule AquirWeb.Router do
  use AquirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AquirWeb.Auth, :assign_user_session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AquirWeb do
    pipe_through :browser # Use the default browser stack

    resources "/users", UserController, param: "username"
    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AquirWeb do
  #   pipe_through :api
  # end
end
