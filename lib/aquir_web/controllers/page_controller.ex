defmodule AquirWeb.PageController do
  use AquirWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
