defmodule MastaniServer.Statistics.Delegate.Geo do
  @moduledoc """
  geo info settings
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Statistics.UserGeoInfo

  def inc_count(city) do
    with {:ok, geo_info} <- UserGeoInfo |> ORM.find_by(~m(city)a) do
      geo_info |> ORM.update(%{value: geo_info.value + 1})
    end
  end

  def list_cities_info do
    UserGeoInfo
    |> where([g], g.value > 0)
    |> ORM.paginater(page: 1, size: 300)
    |> done()
  end
end
