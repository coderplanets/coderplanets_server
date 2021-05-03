defmodule GroupherServer.Repo.Migrations.AddCollectFolderToArticleCollectRecord do
  use Ecto.Migration

  def change do
    alter table(:article_collects) do
      add(:collect_folders, :map)
    end
  end
end
