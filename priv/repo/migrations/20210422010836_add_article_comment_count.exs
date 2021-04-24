defmodule GroupherServer.Repo.Migrations.AddArticleCommentCount do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:article_comments_count, :integer, default: 0)
    end
  end
end
