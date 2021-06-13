defmodule GroupherServer.Repo.Migrations.RenameArticleCommentToComment do
  use Ecto.Migration

  def change do
    rename(table(:articles_comments), to: table(:comments))

    # comment upvotes
    # drop(unique_index(:comments_upvotes, [:user_id, :article_comment_id]))

    # alter table(:comments_upvotes) do
    #   remove(:article_comment_id)
    #   add(:comment_id, references(:comments, on_delete: :delete_all), null: false)
    # end

    # create(unique_index(:comments_upvotes, [:user_id, :comment_id]))
    # comment upvotes end

    # drop(table(:articles_comments_replies))

    # create table(:comments_replies) do
    #   add(:comment_id, references(:comments, on_delete: :delete_all), null: false)

    #   add(:reply_to_id, references(:comments, on_delete: :delete_all), null: false)

    #   timestamps()
    # end

    # create(index(:comments_replies, [:comment_id]))
    # create(index(:comments_replies, [:reply_to_id]))
  end
end
