defmodule GroupherServer.Repo.Migrations.AddFoldToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_folded, :boolean, default: false)
    end
  end
end
