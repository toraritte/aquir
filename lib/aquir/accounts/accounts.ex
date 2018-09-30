defmodule Aquir.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Aquir.{Repo, Router}
  alias Aquir.Accounts.{Commands, Projections}

  def register_user(attrs \\ %{}) do

    # RegisterUser command validation is done here instead
    # of   Aquir.Router  using   Commanded.Middleware  (as
    # described in Building Conduit), because RegisterUser
    # will only be called from the Accounts context. After
    # all,  its  whole  point  is  to  be  an  abstraction
    # boundary for dealing with user management).
    #
    # If the command would need  to be called from another
    # context,  then the  middleware  approach would  make
    # more  sense.  But  then  again,  shouldn't  contexts
    # only interact  with each other through  their public
    # functions?  We'll see  whether I  am oversimplifying
    # things.

    # Used  Ecto.Changeset  instead  of  Vex,  which  also
    # resulted   in    omitting   ExConstructor,   because
    # generating a changeset from  the incoming raw params
    # will result  in "clean" maps (i.e.,  the string keys
    # become  atoms)  thus  Kernel.struct/2  can  be  used
    # to  instantiate  the  RegisterUser struct  with  the
    # changes.
    #
    # See https://stackoverflow.com/questions/30927635/in-elixir-how-do-you-initialize-a-struct-with-a-map-variable
    #
    # CAVEAT:  Using the  changeset  approach requires  to
    # check  the  results   BEFORE  dispatching  the  CQRS
    # command! Otherwise the process will crash after many
    # retries of a faulty event.

    uuid = Ecto.UUID.generate()

    changeset =
      attrs
      |> assign("user_uuid", uuid)
      |> Commands.RegisterUser.changeset()

    with(
      [] <- changeset.errors,
      command = struct(Commands.RegisterUser, changeset.changes),
      :ok <- Router.dispatch(command, consistency: :strong)
    ) do
      get(Projections.User, uuid)
    else
      err -> err
    end
  end

  defp get(projection_schema, uuid) do
    case Repo.get(projection_schema, uuid) do
      nil -> {:error, :not_found}
      projection -> {:ok, projection}
    end
  end

  defp assign(attrs, key, value) do
    Map.put(attrs, key, value)
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
