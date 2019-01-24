defmodule AquirWeb.UserController do
  use AquirWeb, :controller

  alias Aquir.Accounts

  action_fallback AquirWeb.FallbackController

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      users: Accounts.Read.list_users_with_credentials()
    )
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

    # OUTPUT
    # -------
    #  {:ok, user_with_credentials}
    #
    #            taken_error_keywords
    #  {:errors, [{:(username|email)_already_taken, value}]}
    #
    #  { :errors,
    #    [    {:invalid_changesets, [changeset_1, ..., changeset_N]},
    #       | {:(username|email)_already_taken, value}
    #    ]
    #  }

    with(
      {:ok, user_with_credentials} <- Accounts.register_user(user)
    ) do
      username = AquirWeb.UserView.username(user_with_credentials)

      conn
      |> put_flash(:info, "#{username} created!")
      |> redirect(to: user_path(conn, :show, username))

    else
      {:errors, mixed_or_taken_only_keywords} ->
        mixed_or_taken_only_keywords
        |> parse_errors()
        |> (&render(conn, "new.html", errors: &1)).()
    end
  end

# {:errors, cs_with_other} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "aa@a.aaa", "password" => "lofa"})
# {:errors, cs_only} = Aquir.Accounts.register_user(%{"name" => "F", "email" => "@a.a", "password" => "lofa"})

  # 2019-01-24_0810 NOTE (Breaking down `UserController.parse_errors/1`)
  def parse_errors(keywords) do

    parsed_errors =
      Enum.map(
        keywords,
        fn
          # 2019-01-23_0603 NOTE (Why only check for email?)
          ({:email_already_taken, email}) -> email_taken_keyword(email)

          # 2019-01-23_0800 NOTE (Why not `nil`? Or ...)
          ({:username_already_taken, _})  -> []

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

    case List.flatten(parsed_errors) do
      []    -> nil
      other -> other
    end
  end

  defp email_taken_keyword(email) do
    [email: ["Email address #{email} already exists."]]
  end

  defp reduce_errors(_changeset, field, {msg, opts}) do
    field_str =
      field
      |> to_string()
      |> String.capitalize()

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
