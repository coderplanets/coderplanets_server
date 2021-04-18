defmodule GroupherServer.Repo.Migrations.AddMetaToArticleContent do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:meta, :map)
    end

    alter table(:cms_repos) do
      add(:meta, :map)
    end
  end
end
