defmodule GroupherServer.Accounts.Model.Embeds.UserContribute do
  @moduledoc """
  user contribute
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.Embeds

  @optional_fields ~w(reported_count)a

  embedded_schema do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer, default: 0)
    embeds_many(:records, Embeds.UserContributeRecord, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
    |> cast_embed(:records, with: &Embeds.UserContributeRecord.changeset/2)
  end
end
