defmodule Aquir.Users.Write do

  @moduledoc """
  The  Users context  that  deals with  information
  related to users.

  Aggregates in this context:
  + `Aquir.Users.Aggregates.User`
  + `Aquir.Users.Aggregates.Credential`

  Aggregates have their own unique IDs that will be denoted by the `aid` ending. Sometimes that will be used to uniquely identify an entity (e.g., users), but in some cases it only serves to identify the right aggregate instance process to replay the events.

  Authentication workflow
  =======================

  Users can choose from multiple authentication methods: social logins, username & password, etc. After one is chosen, the credentials are submitted to server along with the type of authentication method. For example, for username & password the way to identify the user will be the username and the string "username_password".
  """

  alias Aquir.Commanded.Support, as: ACS
  alias Aquir.Commanded.Router,  as: ACR

  alias Aquir.Users.{
    Commands,
    Unique,
    Read,
  }
  alias Aquir.Contacts

  # TODO Clean up. See NOTE 2018-10-23_0914
  # 2019-01-21_0550 NOTE (`Users.register_user/1` refactor)
  # 2019-01-21_0555 QUESTION (Is this Applicative?)
  # 2019-01-21_0827 TODO (`with/2`-like macro collecting results with deps)
  # 2019-01-21_0954 TODO (Accept only atom maps, or support both?)

  # 2019-02-06_1512 TODO (What if contact persists, but RegisterUser has errors?)
  @doc """
  It will fail,  but contact is in  the system. That
  should be ok, just report what the users error was.
  """

  @doc """
  Phase 1: Check for errors. (Command validation and
           unique claims.)
  Phase 2: Claim username and email.
  Phase 3: Dispatch commands and return new user.

  Failure in  any phase will skip  subsequent phases
  and return erros
  """
  def register_user(
    %Aquir.Contacts.Read.Schemas.Contact{} = contact,
    %{
      "username" => username,
      "password" => password,
    } = user
  ) do

    # 2019-02-05_0612 NOTE (Why generate UUIDs in the context and not in commands?)
    [credential_id, user_id] = ACS.generate_uuids(2)

    imbue_tuples = [
      { %Commands.RegisterUser{},
        %{
          user_id: user_id,
          contact_id: contact.contact_id,
        }
      },
      { %Commands.AddUsernamePasswordCredential{},
        %{
          credential_id: credential_id,
          user_id: user_id,
          payload: %{
            username: username,
            password: password,
          }
        }
      }
    ]

    claims = [username: username]

    ACS.claim_and_dispatch(
      imbue_tuples,
      claims,
      fn() ->
        Read.get_user_with_username_password_credential_by(user_id: user_id)
      end,
      consistency: :strong)

    # OUTPUT
    # -------
    #  {:ok, user_with_username_password_credential}
    #
    #  { :errors,
    #    [   {:invalid_changeset, changeset}
    #      | {:entities_reserved, reserved_keywords}
    #    ]
    #  }

  end
  # c = "d"; Aquir.Users.register_user(%{"name" => "#{c}", "email" => "@#{c}", "username" => "#{c}#{c}", "password" => "#{c}#{c}#{c}"})

# {:errors, cs_with_other} = Aquir.Users.register_user(%{"name" => "F", "email" => "aa@a.aaa", "password" => "lofa"})
# {:errors, cs_only} = Aquir.Users.register_user(%{"name" => "F", "email" => "@a.a", "password" => "lofa"})

  # 2019-01-24_0810 NOTE (Breaking down `UserController.parse_errors/1`)
  def parse_errors(keywords) do

    parsed_errors =
      Enum.map(
        keywords,
        fn
          ({:entities_reserved, keywords}) ->
            Enum.map(keywords, fn({entity, value}) when is_atom(entity)->
              capitalized_entity = atom_to_capitalized_string(entity)
              {entity, ["#{capitalized_entity} #{value} already exists."]}
            end)
          # {:entities_reserved, keywords} ->
          # [email: "Email ... already exists.", username: "..", ...]

          ({:invalid_changeset, %Ecto.Changeset{} = changeset}) ->
            changeset
            # 2019-01-23_0745 NOTE (`traverse_errors/2` example)
            |> Ecto.Changeset.traverse_errors(&reduce_errors/3)
            |> unwrap_add_credential_payload()
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

  # 2019-01-15_1123 NOTE
  @doc """
  Looking  up  the existing  `:credential_id`  because
  this  operation can  fail,  unlike `assign_id/2`  in
  `AddUsernamePasswordCredential`,  and  this  is  not
  a  validation  issue  that  should be  stored  in  a
  changeset, but an input error.
  """

  # !!!
  # Don't   even   bother    looking   at   this   until
  # 2019-01-28_0923 TODO is sorted out
  #
  # def reset_password(
  #   %{
  #     "username"     => username,
  #     "new_password" => new_password
  #   }
  # ) do

  #   # 2019-01-15_1255 TODO (Why query the DB multiple times?)

  #   credential = Read.get(RS.UsernamePasswordCredential, :username, username)

  #   # See 2019-01-21_0827
  #   maybe_fake_credential_id =
  #     (credential != nil && credential.credential_id) || Ecto.UUID.generate()

  #   attrs_with_maybe_fake_credential_id =
  #     %{
  #       credential_id: maybe_fake_credential_id,
  #       username: username,
  #       new_password: new_password
  #      }

  #   imbue_result =
  #     ACS.imbue_commands([
  #       {%Commands.ResetPassword{}, attrs_with_maybe_fake_credential_id}
  #     ])
  #   # {:ok, [reset_password]}
  #   # {:error, [changeset]}

  #   errors = error_filter(
  #     [
  #       imbue_result,
  #       case credential do
  #         nil -> {:error, :user_does_not_exist}
  #         # needs to be wrapped in tuple because of `error_filter/1`
  #         # (only errors are needed anyway)
  #         _ -> {:ok}
  #       end,
  #     ]
  #   )

  #   case length(errors) == 0 do
  #     true  ->
  #       {:ok, [reset_password]} = imbue_result
  #       ACR.dispatch(reset_password, consistency: :strong)
  #       {:ok, :password_changed_succesfully}
  #     false ->
  #       {:errors, errors}
  #   end
  # end

  def delete_user do
    # TODO remove username and email from Unique as well!
  end
end
