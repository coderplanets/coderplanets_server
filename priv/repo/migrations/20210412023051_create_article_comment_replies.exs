defmodule GroupherServer.Repo.Migrations.CreateArticleCommentReplies do
  use Ecto.Migration

  def change do
    create table(:articles_comments_replies) do
      add(:article_comment_id, references(:articles_comments, on_delete: :delete_all), null: false)

      add(:reply_to_id, references(:articles_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:articles_comments_replies, [:article_comment_id]))
    create(index(:articles_comments_replies, [:reply_to_id]))
  end
end
