defmodule GroupherServer.Repo.Migrations.RemoveOldFavoritesStaff do
  use Ecto.Migration

  def change do
    drop(table(:posts_favorites))
    drop(table(:jobs_favorites))
    drop(table(:repos_favorites))

    drop(table(:posts_stars))
    drop(table(:jobs_stars))

    drop(table(:favorite_categories))
  end
end
