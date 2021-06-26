defmodule GroupherServer.Repo.Migrations.AddDrinkToOthers do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:abuse_reports) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:comments) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:pinned_comments) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end

    alter table(:cited_artiments) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all))
    end
  end
end
