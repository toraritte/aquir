defmodule Aquir.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Aquir.{
    Repo,
    Commanded,
  }

  alias Aquir.Accounts.{
    Commands,
    Projections,
  }

  def register_user(attrs \\ %{}) do

    with(
      # `changeset`  needs  to  come first  because  if  the
      # UniqueEmail agent  saves the email  first, but
      # changeset returns  any error, then  subsequent tries
      # will  fail  as the  name  check  will come  back  as
      # already taken.
      {:ok, command} <-
        %Commands.RegisterUser{}
        |> Commanded.Support.imbue_command(attrs),

      # TODO Clean up. See NOTE 2018-10-23_0914
      :ok <- Aquir.Accounts.Support.UniqueEmail.claim(attrs["email"]),
      :ok <- Projections.User.check_email(attrs["email"]),
      :ok <- Commanded.Router.dispatch(command, consistency: :strong)
    ) do
      Projections.User.get_user_by_id(command.user_id)
    # else
    #   err -> err
    end
  end

  def reset_password(attrs \\ %{}) do

    case Commanded.Support.imbue_command(%Commands.ResetPassword{}, attrs) do
      {:ok, command} ->
        Commanded.Router.dispatch(command, consistency: :strong)
        # TODO: what to return?
      errors ->
        errors
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
