defmodule GroupherServer.Repo.Migrations.MoveIsReportedToArticle do
  use Ecto.Migration

  def change do
    alter(table(:cms_posts), do: add(:is_reported, :boolean, default: false))
    alter(table(:cms_jobs), do: add(:is_reported, :boolean, default: false))
    alter(table(:cms_repos), do: add(:is_reported, :boolean, default: false))
  end
end
