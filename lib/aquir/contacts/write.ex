defmodule Aquir.Contacts.Write do

  def register_new_client(
    %{
      "first_name"  => fname,
      "middle_name" => mname,
      "last_name"   => lname,
    }
  ) do
  end

  def add_email(
    %{
      "email" => email
    }
  ) do
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
      "category"       => category, # private or community residential, or commercial
      "type"           => type, # private: rent, own, etc, community: assisted or independent living, nursing home etc.
    }
  ) do
  end

  def add_work_address(
    %{
      "street_address"  => street_address,
      "unit"            => unit,
      "city"            => city,
      "county"          => county,
      "state"           => state,
      "ZIP"             => zip,
      "category"        => "commercial",
      "type"            => "none", # what else?
    }
  ) do
  end
end
