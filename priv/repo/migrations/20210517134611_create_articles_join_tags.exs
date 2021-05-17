defmodule GroupherServer.Repo.Migrations.CreateArticlesJoinTags do
  use Ecto.Migration

  def change do
    create table(:articles_join_tags) do
      add(:article_tag_id, references(:article_tags, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end
  end
end
