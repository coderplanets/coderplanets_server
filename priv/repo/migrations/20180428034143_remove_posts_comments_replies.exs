defmodule GroupherServer.Repo.Migrations.RemovePostsCommentsReplies do
  use Ecto.Migration

  def change do
    drop(table(:posts_comments_replies))

    # drop(index(:posts_comments_replies, [:comment_id]))
    # drop(index(:posts_comments_replies, [:reply_id]))
    # create(unique_index(:posts_comments_replies, [:comment_id, :reply_id]))
  end
end
