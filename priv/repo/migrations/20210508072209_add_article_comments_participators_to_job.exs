defmodule GroupherServer.Repo.Migrations.AddArticleCommentsParticipatorsToJob do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:article_comments_participators, :map)
    end
  end
end
