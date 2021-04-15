defmodule GroupherServer.Repo.Migrations.AddReportedToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_reported, :boolean, default: false)
    end
  end
end
