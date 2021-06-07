defmodule GroupherServer.Repo.Migrations.AddBlogToArticleTags do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:blog_id, references(:cms_jobs, on_delete: :delete_all))
    end
  end
end
