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
      "first_name"  => fname,
      "middle_name" => mname,
      "last_name"   => lname,
    }
  ) do

    [contact_id] = ACS.generate_uuids(1)

    imbue_tuples = [{
      %Commands.AddContact{},
      %{
        contact_id:  contact_id,
        first_name:  fname,
        middle_name: mname,
        last_name:   lname,
      }
    }]

    ACS.no_claim_and_dispatch(
      imbue_tuples,
      # TODO preload all keys that can be preloaded!
      fn() -> Read.get_contact_by(contact_id: contact_id) end,
      consistency: :strong)
  end

  def add_email(
    %RS.Contact{} = contact,
    %{
      "email" => email,
      "type"  => type,
    }
  ) do

    [email_id] = ACS.generate_uuids(1)

    imbue_tuples = [{
      %Commands.AddEmail{},
      %{
        email_id:   email_id,
        contact_id: contact.contact_id,
        email:      email,
        type:       type,
      }
    }]

    claims = [email: email]

    ACS.claim_and_dispatch(
      imbue_tuples,
      claims,
      fn() -> Read.get_email_by(email_id: email_id) end,
      consistency: :strong
    )
  end

  # 2019-02-04_1304 TODO Look up county by address/zip
  # 2019-02-04_1305 TODO Validate email address via USPS API
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
