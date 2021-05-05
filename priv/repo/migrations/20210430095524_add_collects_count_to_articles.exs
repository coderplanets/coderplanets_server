defmodule GroupherServer.Repo.Migrations.AddCollectsCountToArticles do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:collects_count, :integer, default: 0)
    end

    alter table(:cms_jobs) do
      add(:collects_count, :integer, default: 0)
    end

    alter table(:cms_repos) do
      add(:collects_count, :integer, default: 0)
    end
  end
end
