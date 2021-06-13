defmodule GroupherServer.Repo.Migrations.RenameArticlesCommentsUpvotes do
  use Ecto.Migration

  def change do
    rename(table(:articles_comments_upvotes), to: table(:comments_upvotes))
    create(unique_index(:comments_upvotes, [:user_id, :article_comment_id]))

    drop(unique_index(:articles_comments_upvotes, [:user_id, :article_comment_id]))
  end
end
