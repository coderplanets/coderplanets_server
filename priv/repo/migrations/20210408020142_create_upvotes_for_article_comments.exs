defmodule GroupherServer.Repo.Migrations.CreateUpvotesForArticleComments do
  use Ecto.Migration

  def change do
    create table(:articles_comments_upvotes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:article_comment_id, references(:articles_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:articles_comments_upvotes, [:user_id, :article_comment_id]))
  end
end
