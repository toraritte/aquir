defmodule Aquir.Users.Read.Projector do
  use Commanded.Projections.Ecto,
    name: "Aquir.Users",
    repo: Aquir.Repo,
    consistency: :strong

  # 2019-01-16_0506 TODO QUESTION (Get to the bottom of :consistency settings)
  # 2018-10-23_2154 QUESTION (Where is the `:consistency` option defined?)
  # 2019-01-11_0757 NOTE (Projectors.User -> Users.Projector)

  alias Aquir.Commanded.Read, as: ACRead
  alias Aquir.Commanded.Support, as: ACS

  alias Aquir.Users.Read.Schemas, as: RS
  alias Aquir.Users.Events

  @doc """
  The  UserRegistered event  and the  Read.Schemas.User
  struct hold the same keys, hence the conversion, and
  Multi.insert/4  takes  data as  well  in  lieu of  a
  changeset. (Which  is unnecessary because  the event
  is  generated from  the  a command  that is  already
  validated using changesets.)
  """
  project %Events.UserRegistered{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :register_user,
        ACS.convert_struct(event, RS.User)
      )
    end

  # 2019-01-30_0628 NOTE (Credential :type field flip-flop)
  project %Events.UsernamePasswordCredentialAdded{} = event,
    _metadata,
    fn(multi) ->
      Ecto.Multi.insert(
        multi,
        :add_username_password_credential,
        %RS.UsernamePasswordCredential{
          credential_id: event.credential_id,
          user_id:       event.user_id,
          username:      event.payload.username,
          password_hash: event.payload.password_hash,
        }
      )
    end

  # 2018-10-19_2344 TODO QUESTION (How to query the stream's state?)
  project %Events.PasswordReset{} = event,
    _metadata,
    fn(multi) ->
      # No need to check whether credential  exists  because
      # it would have already been catched  in  the  context
      # (`Users.reset_password/1`)

      # 2019-01-15_1255 TODO (Why query the DB multiple times?)
      # 2019-01-11_0819 TODO QUESTION (Why not query the aggregate instance process instead?)

      credential = ACRead.get_by(RS.UsernamePasswordCredential, username: event.username)

      credential
        |> Ecto.Changeset.change(password_hash: event.password_hash)
        |> (&Ecto.Multi.update(multi, :reset_password, &1)).()
    end
end
# Aquir.Users.register_user(%{"email" => "alvaro@miez.com",  "new_password" => "balabab"})
# Aquir.Users.reset_password(%{"email" => "alvaro@miez.com", "new_password" => "mas"})
