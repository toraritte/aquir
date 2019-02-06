defmodule Aquir.Commanded.Read do

  @moduledoc """
  Context-agnostic read model queries.
  """

  import Ecto.Query
  alias Aquir.Repo

  def get_by(schema, keywords) do
    Repo.get_by(schema, keywords)
  end

  def get_all_entity(schema, field) do
    from(e in schema, select: field(e, ^field))
    |> Aquir.Repo.all()
  end
end
