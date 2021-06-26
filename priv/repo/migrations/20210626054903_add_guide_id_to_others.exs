defmodule GroupherServer.Repo.Migrations.AddGuideIdToOthers do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:abuse_reports) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:comments) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:pinned_comments) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end

    alter table(:cited_artiments) do
      add(:guide_id, references(:cms_guides, on_delete: :delete_all))
    end
  end
end
