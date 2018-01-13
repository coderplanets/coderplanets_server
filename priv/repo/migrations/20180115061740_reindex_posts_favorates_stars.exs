defmodule MastaniServer.Repo.Migrations.ReindexPostsFavoratesStars do
  use Ecto.Migration

  def change do
    drop(unique_index(:post_favorites, [:user_id, :post_id]))
    drop(unique_index(:post_stars, [:user_id, :post_id]))
    drop(unique_index(:posts_favorites, [:user_id, :post_id]))
    drop(unique_index(:posts_stars, [:user_id, :post_id]))

    create(unique_index(:posts_favorites, [:user_id, :post_id]))
    create(unique_index(:posts_stars, [:user_id, :post_id]))
  end
end
