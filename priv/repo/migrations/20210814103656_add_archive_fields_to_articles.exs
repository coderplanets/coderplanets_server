defmodule GroupherServer.Repo.Migrations.AddArchiveFieldsToArticles do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_jobs) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_repos) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_blogs) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_works) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_radars) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_guides) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_meetups) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end

    alter table(:cms_drinks) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end
  end
end
