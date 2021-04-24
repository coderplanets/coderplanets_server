defmodule GroupherServer.Repo.Migrations.AddArticleCommentCountToJob do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:article_comments_count, :integer, default: 0)
    end
  end
end
