defmodule GroupherServer.Repo.Migrations.AddBlogReactions do
  use Ecto.Migration

  def change do
    alter table(:abuse_reports) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:articles_comments) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:articles_pinned_comments) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))
    end
  end
end
