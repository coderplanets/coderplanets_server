defmodule GroupherServer.Repo.Migrations.AdjustPinFieldOnArticles do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:is_pinned, :boolean, default: false)
    end

    alter table(:cms_jobs) do
      add(:is_pinned, :boolean, default: false)
    end

    alter table(:cms_repos) do
      add(:is_pinned, :boolean, default: false)
    end

    rename(table(:articles_comments), :is_pined, to: :is_pinned)
  end
end
