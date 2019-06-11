defmodule GroupherServer.Repo.Migrations.CreatePostsStars do
  use Ecto.Migration

  def change do
    create table(:posts_stars) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:posts_stars, [:user_id, :post_id]))
  end
end
