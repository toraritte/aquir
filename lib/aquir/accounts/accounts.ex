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
      ACS.imbue_commands([r_tuple, a_tuple]),
      # {:ok, [register_user, add_credential]}
      # {:error, [changeset_1, ..., changeset_N]}
      Unique.taken?(:email, email),
      Unique.taken?(:username, username),
      # {:ok, :"#{key}_available", value}
      # {:error, :"#{key}_already_taken", value}
    ]

    # require IEx; IEx.pry
    errors = error_filter(results)

    case length(errors) == 0 do

      true ->
        with(
          {:ok, :claim_successful, _keywords} <-
            Unique.claim(username: username, email: email)
        ) do
          [{:ok, [register_user, add_credential]} | _] = results
          ACR.dispatch( register_user,  consistency: :strong)
          ACR.dispatch( add_credential, consistency: :strong)

          {:ok, Read.get_user_by(user_id: register_user.user_id)}

        else
          {:errors, taken_errors_keyword} = errors -> errors
        end

      false ->
        {:errors,
          Enum.map(
            errors,
            fn
              ({:error, reason, taken_keyword} when is_atom(reason)) ->
                {reason, taken_keyword}
              # 2019-01-23_0617 NOTE (homogeneous lists)
              ({:error, changesets} when is_list(changesets)) ->
                {:invalid_changesets, changesets}
            end)
        }
    end

    # OUTPUT
    # -------
    #  {:ok, user_with_credentials}
    #
    #            taken_error_keywords
    #  {:errors, [{:(username|email)_already_taken, value}]}
    #
    #  { :errors,
    #    [    {:invalid_changesets, [changeset_1, ..., changeset_N]},
    #       | {:(username|email)_already_taken, value}
    #    ]
    #  }

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

  def reset_password(
    %{
      "username"     => username,
      "new_password" => new_password
    }
  ) do

    # 2019-01-15_1255 TODO (Why query the DB multiple times?)

    credential = Read.get(RS.Credential, :username, username)

    maybe_fake_credential_id =
        # See 2019-01-21_0827
      (credential != nil && credential.credential_id) || Ecto.UUID.generate()

    attrs_with_maybe_fake_credential_id =
      %{
        credential_id: maybe_fake_credential_id,
        username: username,
        new_password: new_password
       }

    imbue_result =
      ACS.imbue_commands([
        {%C.ResetPassword{}, attrs_with_maybe_fake_credential_id}
      ])
    # {:ok, [reset_password]}
    # {:error, [changeset]}

    errors =
      [
        case credential do
          nil -> {:error, :user_does_not_exist}
          # needs to be wrapped in tuple because of `error_filter/1`
          # (only errors are needed anyway)
          _ -> {:ok}
        end,
        imbue_result
      ]
      |> error_filter()

    case length(errors) == 0 do
      true  ->
        {:ok, [reset_password]} = imbue_result
        ACR.dispatch(reset_password, consistency: :strong)
        {:ok, :password_changed_succesfully}
      false ->
        {:errors, errors}
    end
  end

  defp error_filter(result_list) do
      Enum.filter(
        result_list,
        fn(either_tuple) -> elem(either_tuple, 0) == :error end)
        # `either_tuple` is a tuple of arbitrary size with the
        # first element being either `:ok` or `:error`
  end
end
