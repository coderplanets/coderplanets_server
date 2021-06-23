defmodule GroupherServer.Repo.Migrations.CreaetDomainArticleDocuments do
  use Ecto.Migration

  def change do
    create table(:post_documents) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end

    create table(:job_documents) do
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end

    create table(:repo_documents) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end

    create table(:blog_documents) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end
  end
end
