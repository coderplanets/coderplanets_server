defmodule GroupherServer.Repo.Migrations.AddArticleAuthorIdToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_article_author, :boolean, default: false)
    end
  end
end
