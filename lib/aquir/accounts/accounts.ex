defmodule Aquir.Accounts do

  @moduledoc """
  The  Accounts context  that  deals with  information
  related to users.

  Aggregates in this context:
  + `Aquir.Accounts.Aggregates.User`
  + `Aquir.Accounts.Aggregates.Credential`

  Aggregates have their own unique IDs that will be denoted by the `aid` ending. Sometimes that will be used to uniquely identify an entity (e.g., users), but in some cases it only serves to identify the right aggregate instance process to replay the events.

  Authentication workflow
  =======================

  Users can choose from multiple authentication methods: social logins, username & password, etc. After one is chosen, the credentials are submitted to server along with the type of authentication method. For example, for username & password the way to identify the user will be the username and the string "username_password".
  """

  alias Aquir.Commanded.Support, as: ACS
  alias Aquir.Commanded.Router,  as: ACR

  alias __MODULE__.Commands, as: C
  alias __MODULE__.Support.Unique
  alias __MODULE__.Read
  alias __MODULE__.Read.Schemas, as: RS
  # `alias Read.Schemas, as: RS` would have been enough but being pedantic

  # 2019-01-19_1324 NOTE
  @doc """
  Moving this here from `UserController.new/2` because
  it  is a  business domain  decision to  generate the
  username from the email address.

  Phoenix is  just (albeit huge) wrapper  around these
  contexts.
  """
  def register_user(%{"name" => _, "email" => _, "password" => _} = user)
    when map_size(user) == 3
  do
    user["email"]
    |> String.split("@")
    |> hd()
    |> (&Map.put(user, "username", &1)).()
    |> register_user()
  end

  def register_user(
    %{
      "name"  => name,
      "email" => email,
      # "for_user_id" => , not needed because it is the user_id
      "username" => username,
      "password" => password,
    } = user
  ) when map_size(user) == 4 do

    r_tuple = {
      %C.RegisterUser{},
      %{name:  name, email: email}
    }
    a_tuple = {
      %C.AddUsernamePasswordCredential{},
      %{
        payload: %{
          username: username,
          password: password,
        }
      }
    }

    results = [
      ACS.imbue_command([r_tuple, a_tuple]),
    # {:ok, [register_user, add_credential]} <-
    # {:error, [changeset_1, ..., changeset_N]}
      Unique.taken?(:email, email),
      Unique.taken?(:username, username),
      # {:ok, :"#{key}_available", value}
      # {:error, :"#{key}_already_taken", value}
    ]

    errors =
      Enum.filter(
        results,
        fn({status, _}) -> status == :error end)

    case length(errors) == 0 do
      true ->
        claim_results =
          [username: username, email: email]
          |> Enum.map(
               fn({key, value}) ->
                 Unique.claim(key, value)
                 # {:error, :"#{key}_already_taken", value}
                 # {:ok, :"#{key}_claimed_successfully", value}
               end)
    end
      # TODO Clean up. See NOTE 2018-10-23_0914
      # :ok <- Unique.claim(username),
      # {:error, :username_already_taken, username}

      # :ok <- Read.check_dup(RS.Credential, :username, username),
      # :ok <- Read.check_dup(RS.User,       :email,    email)
      # # {:error, :"#{entity_key}_already_in_database", entity}
    # ) do

      # ACR.dispatch(register_user,  consistency: :strong)
      # ACR.dispatch(add_credential, consistency: :strong)

      # {:ok, Read.get_user_by(user_id: register_user.user_id)}

      # The below happens by default with `with/1`:
      #
      #   else
      #     err -> err
    # end
  end
  # c = "d"; Aquir.Accounts.register_user(%{"name" => "#{c}", "email" => "@#{c}", "username" => "#{c}#{c}", "password" => "#{c}#{c}#{c}"})

  # 2019-01-15_1123 NOTE
  @doc """
  Looking  up  the existing  `:credential_id`  because
  this  operation can  fail,  unlike `assign_id/2`  in
  `AddUsernamePasswordCredential`,  and  this  is  not
  a  validation  issue  that  should be  stored  in  a
  changeset, but an input error.
  """

  def reset_password(%{"username" => username, "new_password" => _} = attrs) do

    with(
    # TODO 2019-01-15_1255 (Why query the DB multiple times?)
      credential when not(is_nil(credential)) <-
        Read.get(RS.Credential, :username, username),

      credential_id <- Map.get(credential, :credential_id),
      attrs_with_id <- Map.put(attrs, "credential_id", credential_id),

      {:ok, [reset_password]} <- ACS.imbue_command([%C.ResetPassword{}, attrs_with_id])
    ) do
      ACR.dispatch(reset_password, consistency: :strong)
      # ACR.dispatch(reset_password, consistency: :strong, include_aggregate_version: true)
    else
      nil -> {:error, :username_not_found}
    end
  end
end
