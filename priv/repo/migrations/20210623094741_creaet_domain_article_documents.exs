defmodule GroupherServer.Repo.Migrations.CreaetDomainArticleDocuments do
  use Ecto.Migration

  def change do
    create table(:post_documents) do
      add(:thread, :string)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:title, :string)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)

      timestamps()
    end

    create table(:job_documents) do
      add(:thread, :string)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:title, :string)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)

      timestamps()
    end

    create table(:repo_documents) do
      add(:thread, :string)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:title, :string)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)

      timestamps()
    end

    create table(:blog_documents) do
      add(:thread, :string)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:title, :string)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)

      timestamps()
    end
  end
end
