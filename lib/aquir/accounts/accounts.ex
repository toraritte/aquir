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

  alias Aquir.Repo
  import Ecto.Query

  alias __MODULE__.Commands, as: C
  alias __MODULE__.Read
  alias __MODULE__.Read.Schemas, as: RS
  # `alias Read.Schemas, as: RS` would have been enough but being pedantic

  def register_user(
    %{
      "name"  => name,
      "email" => email,
      # "for_user_id" => , not needed because it is the user_id
      "username" => username,
      "password" => password,
    }
  ) do

    with(
      # `changeset`  needs  to  come first  because  if  the
      # UniqueUsername agent  saves the username  first, but
      # changeset returns  any error, then  subsequent tries
      # will  fail  as the  name  check  will come  back  as
      # already taken.
      {:ok, register_user} <-
        ACS.imbue_command(
          %C.RegisterUser{},
          %{
            name:  name,
            email: email
           }),

      {:ok, add_username_password_credential} <-
        ACS.imbue_command(
          %C.AddUsernamePasswordCredential{},
          %{
            for_user_id: register_user.user_id,
            payload: %{
              username: username,
              password: password,
            }
           }),

      # TODO Clean up. See NOTE 2018-10-23_0914
      :ok <- __MODULE__.Support.UniqueUsername.claim(username),
      :ok <- Read.check_dup(RS.Credential, :username, username),

      :ok <- Read.check_dup(RS.User, :email, email)
    ) do
      ACR.dispatch(register_user, consistency: :strong)
      ACR.dispatch(add_username_password_credential, consistency: :strong)

      # {ACR.dispatch(register_user, consistency: :strong, include_execution_result: true),
      # ACR.dispatch(add_username_password_credential, consistency: :strong, include_execution_result: true)}

      # Read.get_user_by_id(register_user.user_id)

    # This happens by default with `with/1`
    # else
    #   err -> err
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
      credential when not(is_nil(credential)) <- Read.get(RS.Credential, :username, username),
      credential_id <- Map.get(credential, :credential_id),
      attrs_with_id <- Map.put(attrs, "credential_id", credential_id),
      {:ok, reset_password} <- ACS.imbue_command(%C.ResetPassword{}, attrs_with_id)
    ) do
      ACR.dispatch(reset_password, consistency: :strong)
      # ACR.dispatch(reset_password, consistency: :strong, include_aggregate_version: true)
    else
      nil -> {:error, :username_not_found}
    end
  end

  defp all_users_with_credentials_query do
      from u in RS.User,
        join: c in RS.Credential,
        on: u.user_id == c.for_user_id,
        preload: [credentials: c]
  end

  defp user_with_credential_by_user_id_query(user_id) do
    from q in all_users_with_credentials_query(),
      where: q.user_id == ^user_id
  end

  def list_users_with_credentials do
    Repo.all all_users_with_credentials_query()
  end

  def get_user_by_id(user_id) do
    Repo.one user_with_credential_by_user_id_query(user_id)
  end
end
