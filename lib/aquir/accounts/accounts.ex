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
      # Read.get_user_by_id(register_user.user_id)
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
    else
      nil -> {:error, :username_not_found}
    end
  end

#   import Ecto.Query, warn: false
#   alias Aquir.Repo

#   alias Aquir.Accounts.User

#   @doc """
#   Returns the list of users.

#   ## Examples

#       iex> list_users()
#       [%User{}, ...]

#   """
#   def list_users do
#     Repo.all(User)
#   end

#   @doc """
#   Gets a single user.

#   Raises `Ecto.NoResultsError` if the User does not exist.

#   ## Examples

#       iex> get_user!(123)
#       %User{}

#       iex> get_user!(456)
#       ** (Ecto.NoResultsError)

#   """
#   def get_user!(id), do: Repo.get!(User, id)

#   @doc """
#   Creates a user.

#   ## Examples

#       iex> create_user(%{field: value})
#       {:ok, %User{}}

#       iex> create_user(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
#   def create_user(attrs \\ %{}) do
#     %User{}
#     |> User.changeset(attrs)
#     |> Repo.insert()
#   end

#   @doc """
#   Updates a user.

#   ## Examples

#       iex> update_user(user, %{field: new_value})
#       {:ok, %User{}}

#       iex> update_user(user, %{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
#   def update_user(%User{} = user, attrs) do
#     user
#     |> User.changeset(attrs)
#     |> Repo.update()
#   end

#   @doc """
#   Deletes a User.

#   ## Examples

#       iex> delete_user(user)
#       {:ok, %User{}}

#       iex> delete_user(user)
#       {:error, %Ecto.Changeset{}}

#   """
#   def delete_user(%User{} = user) do
#     Repo.delete(user)
#   end

#   @doc """
#   Returns an `%Ecto.Changeset{}` for tracking user changes.

#   ## Examples

#       iex> change_user(user)
#       %Ecto.Changeset{source: %User{}}

#   """
#   def change_user(%User{} = user) do
#     User.changeset(user, %{})
#   end
end
