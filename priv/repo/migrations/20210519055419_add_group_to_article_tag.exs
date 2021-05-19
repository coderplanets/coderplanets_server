defmodule GroupherServer.Repo.Migrations.AddGroupToArticleTag do
  use Ecto.Migration

  def change do
    alter table(:article_tags) do
      add(:group, :string)
    end
  end
end
