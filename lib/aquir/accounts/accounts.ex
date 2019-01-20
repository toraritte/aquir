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

    with(
      # `changeset`  needs  to  come first  because  if  the
      # UniqueUsername agent  saves the username  first, but
      # changeset returns  any error, then  subsequent tries
      # will  fail  as the  name  check  will come  back  as
      # already taken.
      register_user_tuple = {
        %C.RegisterUser{},
        %{name:  name, email: email}
      },
      add_credential_tuple = {
        %C.AddUsernamePasswordCredential{},
        %{
          payload: %{
            username: username,
            password: password,
          }
        }
      },
      {:ok, [register_user, add_credential]} <-
        ACS.imbue_command([register_user_tuple, add_credential_tuple]),
      # {:error, [changeset_1, ..., changeset_N]}

      # TODO Clean up. See NOTE 2018-10-23_0914
      :ok <- __MODULE__.Support.UniqueUsername.claim(username),
      # {:error, :username_already_taken}

      :ok <- Read.check_dup(RS.Credential, :username, username),
      :ok <- Read.check_dup(RS.User, :email, email),
      # {:error, [:"#{entity_key}_already_in_database", entity]}

      :ok <- ACR.dispatch(register_user, consistency: :strong),
      :ok <- ACR.dispatch(add_credential, consistency: :strong)
    ) do
      {:ok, Read.get_user_by(user_id: register_user.user_id)}
      # The below happens by default with `with/1`:
      #
      #   else
      #     err -> err
    end
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
