defmodule Aquir.Clients.Write do

  def register_new_client(
    %{
      "first_name"  => fname,
      "middle_name" => mname,
      "last_name"   => lname,
    }
  ) do
  end

  # 2019-02-04_1304 TODO Look up county by address/zip
  # 2019-02-04_1305 TODO Validate email address via USPS API
  def add_address(
    %{

    }
  ) do
  end
end
