defmodule GroupherServer.Repo.Migrations.CreateGeoInfo do
  use Ecto.Migration

  def change do
    create table(:geos) do
      add(:city, :string)
      add(:long, :float)
      add(:lant, :float)
      add(:value, :integer, default: 0)

      timestamps()
    end

    create(unique_index(:geos, [:city]))
  end
end
