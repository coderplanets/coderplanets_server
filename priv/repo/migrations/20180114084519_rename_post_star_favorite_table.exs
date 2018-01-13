defmodule MastaniServer.Repo.Migrations.RenamePostStarFavoriteTable do
  use Ecto.Migration

  def change do
    rename(table("post_stars"), to: table("posts_stars"))
    rename(table("post_favorites"), to: table("posts_favorites"))

    create(unique_index(:posts_favorites, [:user_id, :post_id]))
    create(unique_index(:posts_stars, [:user_id, :post_id]))
  end
end
