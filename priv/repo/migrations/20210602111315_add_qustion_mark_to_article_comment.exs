defmodule GroupherServer.Repo.Migrations.AddQustionMarkToArticleComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_for_question, :boolean, default: false)
    end
  end
end
