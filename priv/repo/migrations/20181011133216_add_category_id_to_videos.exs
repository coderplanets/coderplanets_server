defmodule GroupherServer.Repo.Migrations.AddCategoryIdToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos_favorites) do
      add(:category_id, references(:favorite_categories, on_delete: :delete_all))
    end

    create(index(:videos_favorites, [:category_id]))
  end
end
