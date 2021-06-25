defmodule GroupherServer.Repo.Migrations.AddWorksToOtherJoinTables do
  use Ecto.Migration

  def change do
    alter table(:abuse_reports) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:comments) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:pinned_comments) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end
  end
end
