defmodule GroupherServer.Accounts.Model.Embeds.UserContributeRecord do
  @moduledoc """
  user contribute
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  @optional_fields ~w(count date)a

  embedded_schema do
    field(:count, :integer)
    field(:date, :date)
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
