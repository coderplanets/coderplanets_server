defmodule GroupherServer.Repo.Migrations.AddFloorToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:floor, :integer, default: 0)
    end
  end
end
