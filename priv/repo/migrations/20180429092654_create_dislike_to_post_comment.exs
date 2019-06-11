defmodule GroupherServer.Repo.Migrations.CreateDislikeToPostComment do
  use Ecto.Migration

  def change do
    create table(:posts_comments_dislikes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:post_comment_id, references(:posts_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:posts_comments_dislikes, [:user_id, :post_comment_id]))
  end
end
