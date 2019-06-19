defmodule GroupherServer.Repo.Migrations.CreatePostsViewers do
  use Ecto.Migration

  def change do
    create table(:posts_viewers) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:posts_viewers, [:post_id, :user_id]))
  end
end
