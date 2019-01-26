defmodule AquirWeb.UserController do
  use AquirWeb, :controller

  alias Aquir.Accounts

  action_fallback AquirWeb.FallbackController

  def index(conn, _params) do
    case AquirWeb.Auth.authenticate(conn) do
      %Plug.Conn{halted: true} ->
        conn
      conn ->
        users = Accounts.Read.list_users_with_credentials()
        render(conn, "index.html", users: users)
    end
  end

  def show(conn, %{"username" => username}) do
    render(
      conn,
      "show.html",
      user: Accounts.Read.get_user_by(username: username)
    )
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

    with(
      {:ok, user_with_credentials} <- Accounts.register_user(user)
    ) do
      username = AquirWeb.UserView.username(user_with_credentials)

      conn
      |> put_flash(:info, "User #{username} created!")
      # 2019-01-25_1547 QUESTION (Adding 201 and Location does weird stuff)
      |> redirect(to: Routes.user_path(conn, :show, username))

    else
      {:errors, errors} ->
        conn
        |> put_status(:bad_request)
        |> render("new.html", errors: parse_errors(errors))
    end
  end

# {:errors, cs_with_other} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "aa@a.aaa", "password" => "lofa"})
# {:errors, cs_only} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "@a.a", "password" => "lofa"})

  # 2019-01-24_0810 NOTE (Breaking down `UserController.parse_errors/1`)
  def parse_errors(keywords) do

    # OUTPUT
    # -------
    #  {:ok, user_with_credentials}
    #
    #  { :errors,
    #    [ {:invalid_changesets, changeset_list}
    #    , {:entities_reserved,  reserved_keywords}
    #    ]
    #  }

    parsed_errors =
      Enum.map(
        keywords,
        fn
          ({:entities_reserved, keywords}) ->
            Enum.map(keywords, fn({entity, value}) ->
              capitalized_entity = atom_to_capitalized_string(entity)
              {entity, ["#{capitalized_entity} #{value} already exists."]}
            end)

          # 2019-01-23_0745 NOTE (`traverse_errors/2` example)
          ({:invalid_changesets, changesets}) ->
            Enum.reduce(changesets, %{}, fn(changeset, acc) ->
              changeset
              |> Ecto.Changeset.traverse_errors(&reduce_errors/3)
              |> unwrap_add_credential_payload()
              |> Map.merge(acc)
            end)
            |> Map.to_list()
        end)

    # require IEx; IEx.pry
    List.flatten(parsed_errors)

    # 2019-01-25_0749 NOTE (Illogical to check for no errors in `parse_errors/1`)
    # case List.flatten(parsed_errors) do
    #   []    -> nil
    #   error_keywords -> error_keywords
    # end
  end

  defp atom_to_capitalized_string(atom) do
      atom
      |> to_string()
      |> String.capitalize()
  end

  defp reduce_errors(_changeset, field, {msg, opts}) when is_atom(field) do
    field_str = atom_to_capitalized_string(field)
    Enum.reduce(opts, "#{field_str} #{msg}", fn({key, value}, acc) ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  # 2019-01-24_0902 !!!NOTE!!!
  @doc """
  If there are keys in  the map other than `:payload`,
  those will be ignored!

  The     only     content     relevant     in     the
  `AddUsernamePasswordCredential`   command    is   in
  the   payload,   everything   else  is   static   or
  auto-generated.
  """
  defp unwrap_add_credential_payload(%{payload: payload}), do: payload
  defp unwrap_add_credential_payload(map), do: map

  def rec_map_to_list(nested_maps) do

    mlist = Map.to_list(nested_maps)

    Enum.map(
      Keyword.keys(mlist),
      fn(key) ->
        {
          key,
          case mlist[key] do
            next_map when is_map(next_map) ->
              rec_map_to_list(next_map)
            value -> value
          end
        }
    end)
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
