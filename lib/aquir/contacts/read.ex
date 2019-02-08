defmodule Aquir.Contacts.Read do

  import Ecto.Query

  alias Aquir.Repo
  alias Aquir.Commanded.Read, as: ACRead
  alias __MODULE__.Schemas, as: RS

  def get_email_by([email_id: _] = keyword) do
    ACRead.get_by(RS.Email, keyword)
  end

  def get_contact_by([contact_id: _] = keyword) do
    ACRead.get_by(RS.Contact, keyword)
  end

  def preload_emails(%RS.Contact{} = contact) do
    Repo.preload(contact, :email)
  end
end
