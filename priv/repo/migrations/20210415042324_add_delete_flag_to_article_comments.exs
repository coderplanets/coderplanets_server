defmodule GroupherServer.Repo.Migrations.AddDeleteFlagToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_deleted, :boolean, default: false)
    end
  end
end
