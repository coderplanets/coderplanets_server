defmodule GroupherServer.Repo.Migrations.AddMetaToArticleComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:meta, :map)
    end
  end
end
