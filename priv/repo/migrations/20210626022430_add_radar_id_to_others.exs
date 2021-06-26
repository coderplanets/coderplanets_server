defmodule GroupherServer.Repo.Migrations.AddRadarIdToOthers do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:abuse_reports) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:comments) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:pinned_comments) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end

    alter table(:cited_artiments) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all))
    end
  end
end
