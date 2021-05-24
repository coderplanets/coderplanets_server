defmodule GroupherServer.Repo.Migrations.AddArticleTagsCount do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:article_tags_count, :integer, default: 0)
      add(:threads_count, :integer, default: 0)
    end
  end
end
