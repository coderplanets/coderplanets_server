defmodule MastaniServer.Repo.Migrations.AddIndexUsersPostsStars do
  use Ecto.Migration

  def change do
    create(unique_index(:users_posts_stars, [:user_id, :post_id]))
  end
end
