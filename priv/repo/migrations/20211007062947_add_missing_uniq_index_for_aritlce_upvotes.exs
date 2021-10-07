defmodule GroupherServer.Repo.Migrations.AddMissingUniqIndexForAritlceUpvotes do
  use Ecto.Migration

  def change do
    create(unique_index(:article_upvotes, [:user_id, :meetup_id]))
    create(unique_index(:article_upvotes, [:user_id, :drink_id]))
    create(unique_index(:article_upvotes, [:user_id, :blog_id]))
    create(unique_index(:article_upvotes, [:user_id, :works_id]))
    create(unique_index(:article_upvotes, [:user_id, :radar_id]))
    create(unique_index(:article_upvotes, [:user_id, :guide_id]))
  end
end
