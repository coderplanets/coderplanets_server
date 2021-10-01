defmodule GroupherServer.Repo.Migrations.CreateWorksJoinCityies do
  use Ecto.Migration

  def change do
    create table(:works_join_cities) do
      add(:works_id, references(:cms_works, on_delete: :delete_all), null: false)
      add(:city_id, references(:cms_cities, on_delete: :delete_all), null: false)
    end

    create(unique_index(:works_join_cities, [:works_id, :city_id]))
  end
end
