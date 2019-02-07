defmodule AquirWeb.Router do
  use AquirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AquirWeb.Auth, :assign_maybe_user_to_conn
  end

  # 2019-02-07_0944 NOTE (Why is this not in the `:browser` pipeline?)
  pipeline :user_auth do
    plug AquirWeb.Auth, :authorize_user_if_signed_in
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AquirWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get    "/login",  SessionController, :new
    post   "/login",  SessionController, :create
    delete "/logout", SessionController, :delete
  end

  scope "/admin", AquirWeb do
    pipe_through [:browser, :user_auth]

    resources "/users", UserController, param: "username"
    # GET    /users          => :index
    # GET    /users/new      => :new
    # POST   /users          => :create
    # GET    /users/:id      => :show
    # GET    /users/:id/edit => :edit
    # PATCH  /users/:id      => :update
    # PUT    /users/:id      => :update
    # DELETE /users/:id      => :delete
    #  Options

    # :only   - a list of actions to generate routes for
    # :except - a list of actions to exclude generated routes from
    # :param  - the name of the parameter for this resource, defaults
    #           to "id"
    # :name   - the  prefix  for this  resource.  This  is used  for
    #           the  named   helper  and  as  the   prefix  for  the
    #           parameter in nested resources.  The default value is
    #           automatically derived from the controller name, i.e.
    #           UserController will have name "user"
    # :as     - configures the named helper exclusively
    # :singleton - defines  routes for  a  singleton  resource that  is
    #              looked up  by the client without  referencing an ID.
    #              Read below for more information
  end

  # Other scopes may use custom stacks.
  # scope "/api", AquirWeb do
  #   pipe_through :api
  # end
end
