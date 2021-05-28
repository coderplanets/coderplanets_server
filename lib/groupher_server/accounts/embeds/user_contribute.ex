defmodule GroupherServer.Accounts.Embeds.UserContribute do
  @moduledoc """
  user contribute
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.Accounts.Embeds

  @optional_fields ~w(reported_count)a

  # object :contribute do
  #   field(:date, :date)
  #   field(:count, :integer)
  # end

  # object :contribute_map do
  #   field(:start_date, :date)
  #   field(:end_date, :date)
  #   field(:total_count, :integer)
  #   field(:records, list_of(:contribute))
  # end

  # %{
  #   end_date: ~D[2021-05-25],
  #   records: [%{count: 1, date: ~D[2021-05-25]}],
  #   start_date: ~D[2020-11-25],
  #   total_count: 1
  # }

  @default_meta %{
    reported_count: 0,
    reported_user_ids: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer, default: 0)
    embeds_many(:records, Embeds.UserContributeRecord)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
    |> cast_embed(:records, with: &Embeds.UserContributeRecord.changeset/2)
  end
end
