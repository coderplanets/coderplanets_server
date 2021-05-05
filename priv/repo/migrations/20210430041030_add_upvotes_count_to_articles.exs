defmodule GroupherServer.Repo.Migrations.AddUpvotesCountToArticles do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:upvotes_count, :integer, default: 0)
    end

    alter table(:cms_jobs) do
      add(:upvotes_count, :integer, default: 0)
    end

    alter table(:cms_repos) do
      add(:upvotes_count, :integer, default: 0)
    end
  end
end
