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

  # NOTE 2018-10-11_2312
  @doc """
  RegisterUser command validation is done here instead
  of Aquir.Commanded.Router  using Commanded.Middleware,
  (as   described   in  Building   Conduit),   because
  RegisterUser will  only be called from  the Accounts
  context.  After  all,  its  whole  point  is  to  be
  an  abstraction  boundary   for  dealing  with  user
  management).

  If the command would need  to be called from another
  context,  then the  middleware  approach would  make
  more  sense.  But  then  again,  shouldn't  contexts
  only interact  with each other through  their public
  functions?  We'll see  whether I  am oversimplifying
  things.

  Used  Ecto.Changeset  instead  of  Vex,  which  also
  resulted   in    omitting   ExConstructor,   because
  generating a changeset from  the incoming raw params
  will result  in "clean" maps (i.e.,  the string keys
  become  atoms)  thus  Kernel.struct/2  can  be  used
  to  instantiate  the  RegisterUser struct  with  the
  changes.

  See https://stackoverflow.com/questions/30927635/in-elixir-how-do-you-initialize-a-struct-with-a-map-variable

  CAVEAT:  Using the  changeset  approach requires  to
  check  the  results   BEFORE  dispatching  the  CQRS
  command! Otherwise the process will crash after many
  retries of a faulty event.
  """

  # NOTE 2018-10-18_0004
  @doc """
  Keeping command validation here as  I am not fond of
  the  Commanded.Middleware  implementation. See  note
  "2018-10-19_2246" in Aquir.Commanded.Router.
  """

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

  # NOTE TODO(?) 2019-01-04_1148
  @doc """
  
  iex(11)>   defmodule NewOrderCommand do
  ...(11)>     use Ecto.Schema
  ...(11)>     import Ecto.Changeset
  ...(11)> 
  ...(11)>     embedded_schema do
  ...(11)>       field :user_id, Ecto.UUID
  ...(11)> 
  ...(11)>       embeds_one :address, Address do
  ...(11)>         field :street, :string
  ...(11)>         field :country, :string
  ...(11)>       end
  ...(11)> 
  ...(11)>       embeds_many :items, Item do
  ...(11)>         field :item_id, Ecto.UUID
  ...(11)>         field :quantity, :integer
  ...(11)>       end
  ...(11)>     end
  ...(11)> 
  ...(11)>     def changeset(struct, params) do
  ...(11)>       struct
  ...(11)>       |> cast(params, [:user_id])
  ...(11)>       |> cast_embed(:address, with: &address_changeset/2)
  ...(11)>       |> cast_embed(:items, with: &item_changeset/2)
  ...(11)>       |> validate_required([:user_id, :address, :items])
  ...(11)>     end
  ...(11)> 
  ...(11)>     defp address_changeset(struct, params) do
  ...(11)>       struct
  ...(11)>       |> cast(params, [:street, :city])
  ...(11)>       |> validate_required([:street, :city])
  ...(11)>       # |> validate_existing_city
  ...(11)>       # |> find_location
  ...(11)>     end
  ...(11)> 
  ...(11)>     defp item_changeset(struct, params) do
  ...(11)>         struct
  ...(11)>         |> cast(params, [:item_id, :quantity])
  ...(11)>         |> validate_required([:item_id, :quantity])
  ...(11)>         |> validate_number(:quantity, min: 0)
  ...(11)>     end
  ...(11)>   end

  {:module, NewOrderCommand,
  <<70, 79, 82, 49, 0, 0, 17, 56, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 2, 105,
    0, 0, 0, 58, 22, 69, 108, 105, 120, 105, 114, 46, 78, 101, 119, 79, 114, 100,
    101, 114, 67, 111, 109, 109, 97, 110, 100, ...>>, {:item_changeset, 2}}

  iex(12)> NewOrderCommand.changeset(%NewOrderCommand{}, %{})
  #Ecto.Changeset<
    action: nil,
    changes: %{},
    errors: [
      user_id: {"can't be blank", [validation: :required]},
      address: {"can't be blank", [validation: :required]}
    ],
    data: #NewOrderCommand<>,
    valid?: false
  """

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
