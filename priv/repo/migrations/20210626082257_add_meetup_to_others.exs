defmodule GroupherServer.Repo.Migrations.AddMeetupToOthers do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:abuse_reports) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:article_collects) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:article_upvotes) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:comments) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:pinned_comments) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:articles_users_emotions) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:pinned_articles) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end

    alter table(:cited_artiments) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all))
    end
  end
end
