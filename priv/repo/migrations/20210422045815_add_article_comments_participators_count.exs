defmodule GroupherServer.Repo.Migrations.AddArticleCommentsParticipatorsCount do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:article_comments_participators_count, :integer, default: 0)
    end

    alter table(:cms_jobs) do
      add(:article_comments_participators_count, :integer, default: 0)
    end
  end
end
