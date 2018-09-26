defmodule MastaniServer.Repo.Migrations.AddGeoInfoToCommunity do
  use Ecto.Migration
  alias MastaniServer.Support.GeoData

  def change do
    alter table(:communities) do
      add(:geo_info, :map, default: %{data: GeoData.all()})
    end
  end
end
