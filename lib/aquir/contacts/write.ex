defmodule Aquir.Contacts.Write do

  alias Aquir.Commanded.Support, as: ACS
  # alias Aquir.Commanded.Router,  as: ACR

  alias Aquir.Contacts.{
    Read,
    Commands,
  }
  alias Read.Schemas, as: RS

  def add_contact(
    %{
      contact_id:  contact_id,
      first_name:  fname,
      middle_name: mname,
      last_name:   lname,
    } = params
  ) do
    ACS.claim_and_imbue(
      Commands.AddContact,
      params,
      claims: [],
      consistency: :strong
    )
  end

  def add_email(%{ email: email} = params)
    when map_size(params) == 1
  do
    add_email(%{email: email, type: ""})
  end

  def add_email(
    %{
      email_id:   email_id,
      contact_id: contact_id,
      email: email,
      type:  type,
    } = params
  ) do
    ACS.claim_and_imbue(
      Commands.AddEmail,
      params,
      claims: [email: email],
      consistency: :strong
    )
  end

  # 2019-02-04_1304 TODO Look up county by address/zip
  # 2019-02-04_1305 TODO Validate address via USPS API
  def add_home_address(
    %{
      "street_address" => street_address,
      "unit"           => unit,
      "city"           => city,
      "county"         => county,
      "state"          => state,
      "ZIP"            => zip,
      "category"       => category, #  commercial, private or community residential
      "type"           => type, # private: rent, own, etc, community: assisted or independent living, nursing home etc.
    }
  ) do
  end

  def add_work_address(
    %{
      "street_address" => street_address,
      "unit"           => unit,
      "city"           => city,
      "county"         => county,
      "state"          => state,
      "ZIP"            => zip,
      "category"       => "commercial",
      "type"           => "none", # what else?
    }
  ) do
  end

  def add_phone_number() do
  end
end
