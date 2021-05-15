defmodule GroupherServer.Repo.Migrations.AddMarkDeleteForArticles do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:mark_delete, :boolean, default: false)
    end

    alter table(:cms_jobs) do
      add(:mark_delete, :boolean, default: false)
    end

    alter table(:cms_repos) do
      add(:mark_delete, :boolean, default: false)
    end
  end
end
