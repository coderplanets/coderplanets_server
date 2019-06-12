defmodule GroupherServer.Repo.Migrations.ReplaceCategoryIdToPostsFavorites do
  use Ecto.Migration

  def change do
    alter table(:posts_favorites) do
      add(:category_id, references(:favorite_categories, on_delete: :delete_all))
    end
  end
end
