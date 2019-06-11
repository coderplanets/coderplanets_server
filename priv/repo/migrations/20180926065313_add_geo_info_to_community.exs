defmodule GroupherServer.Repo.Migrations.AddGeoInfoToCommunity do
  use Ecto.Migration
  alias Helper.GeoPool

  def change do
    alter table(:communities) do
      add(:geo_info, :map, default: %{data: GeoPool.all()})
    end
  end
end
