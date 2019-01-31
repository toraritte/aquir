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

  alias __MODULE__.{
    Commands,
    # Events,
    Unique,
    Read,
  }

  # alias Read.Schemas, as: RS

  # 2019-01-19_1324 NOTE
  @doc """
  Moving this here from `UserController.new/2` because
  it  is a  business domain  decision to  generate the
  username from the email address.

  Phoenix is  just (albeit huge) wrapper  around these
  contexts.
  """
  def register_user(%{"name" => _, "email" => email, "password" => _} = user)
    when map_size(user) == 3
  do
    email
    |> String.split("@")
    |> hd()
    |> (&Map.put(user, "username", &1)).()
    |> register_user()
  end

  # TODO Clean up. See NOTE 2018-10-23_0914
  # 2019-01-21_0550 NOTE (`Accounts.register_user/1` refactor)
  # 2019-01-21_0555 QUESTION (Is this Applicative?)
  # 2019-01-21_0827 TODO (`with/2`-like macro collecting results with deps)
  # 2019-01-21_0954 TODO (Accept only atom maps, or support both?)

  @doc """
  Phase 1: Check for errors. (Command validation and
           unique claims.)
  Phase 2: Claim username and email.
  Phase 3: Dispatch commands and return new user.

  Failure in  any phase will skip  subsequent phases
  and return erros
  """
  def register_user(
    %{
      "name"  => name,
      "email" => email,
      "username" => username,
      "password" => password,
    } = user
  ) when map_size(user) == 4 do

    [new_credential_id, new_user_id] = generate_uuids(2)

    maybe_register_user =
      ACS.imbue_command(
        %Commands.RegisterUser{},
        %{user_id: new_user_id, name: name, email: email}
      )

    maybe_add_credential =
      ACS.imbue_command(
        %Commands.AddUsernamePasswordCredential{},
        %{
          credential_id: new_credential_id,
          user_id: new_user_id,
          payload: %{
            username: username,
            password: password,
          }
        }
      )

    claims = [username: username, email: email]
    # 2019-01-25_1023 NOTE (Why `check/1` needed and not just `claim/1`?)
    claim_check = Unique.check(claims)

    results = [
      maybe_register_user,
      maybe_add_credential,
      # {:ok,    command_struct}
      # {:error, changeset}
      claim_check
      # {:ok,    :entities_free,     keywords}
      # {:error, :entities_reserved, reserved}
    ]

    # require IEx; IEx.pry
    filtered_errors = error_filter(results)

    # switched from `case..do`, will see in a couple months
    with(
      true <- length(filtered_errors) == 0,
      {:ok, :claim_successful, _keywords} <- Unique.claim(claims)
    ) do
      [{:ok, register_user}, {:ok, add_credential}, {:ok, _, _}] = results
      ACR.dispatch( register_user,  consistency: :strong)
      ACR.dispatch( add_credential, consistency: :strong)
      {:ok, Read.get_user_with_usrname_password_credential_by(user_id: register_user.user_id)}
    else
      false -> {:errors, transform(filtered_errors)}
      {:error, :entities_reserved, _} = errors -> {:errors, errors}
    end

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
  # c = "d"; Aquir.Accounts.register_user(%{"name" => "#{c}", "email" => "@#{c}", "username" => "#{c}#{c}", "password" => "#{c}#{c}#{c}"})

  defp transform(errors) do

    Enum.map(
      errors,
      fn
        ({:error, :entities_reserved, reserved}) ->
          {:entities_reserved, reserved}
        ({:error, %Ecto.Changeset{} = cs}) ->
          {:invalid_changeset, cs}
        # 2019-01-23_0617 NOTE (homogeneous lists)
        # ({:error, changesets} when is_list(changesets)) ->
        #   {:invalid_changesets, changesets}
      end)
  end

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

  defp error_filter(result_list) do
      Enum.filter(
        result_list,
        fn(either_tuple) -> elem(either_tuple, 0) == :error end)
        # `either_tuple` is a tuple of arbitrary size with the
        # first element being either `:ok` or `:error`
  end

  def delete_user do
    # TODO remove username and email from Unique as well!
  end

  defp generate_uuids(n), do: for _ <- 1..n, do: Ecto.UUID.generate()
end
