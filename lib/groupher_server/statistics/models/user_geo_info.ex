defmodule GroupherServer.Statistics.Model.UserGeoInfo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(city long lant)a
  @optional_fields ~w(value)a

  @type t :: %UserGeoInfo{}
  schema "geos" do
    field(:city, :string)
    field(:long, :float)
    field(:lant, :float)
    field(:value, :integer, default: 0)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%UserGeoInfo{} = user_geo_info, attrs) do
    user_geo_info
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%UserGeoInfo{} = user_geo_info, attrs) do
    user_geo_info
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
