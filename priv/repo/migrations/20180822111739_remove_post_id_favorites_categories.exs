defmodule GroupherServer.Repo.Migrations.RemovePostIdFavoritesCategories do
  use Ecto.Migration

  def change do
    alter table(:favorite_categories) do
      remove(:post_id)
    end
  end
end
