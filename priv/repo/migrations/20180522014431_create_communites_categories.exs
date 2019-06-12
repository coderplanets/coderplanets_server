defmodule GroupherServer.Repo.Migrations.CreateCommunitesCategories do
  use Ecto.Migration

  def change do
    create table(:communities_categories) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:category_id, references(:categories, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:communities_categories, [:community_id, :category_id]))
  end
end
