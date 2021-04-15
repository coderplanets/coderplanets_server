defmodule GroupherServer.Repo.Migrations.AddUpvoteCountToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:upvotes_count, :integer, default: 0)
    end
  end
end
