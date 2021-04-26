defmodule GroupherServer.Repo.Migrations.RemoveTopicTables do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      remove(:topic_id)
    end

    drop(unique_index(:pined_posts, [:post_id, :community_id, :topic_id]))

    alter table(:pined_posts) do
      remove(:topic_id)
    end

    create(unique_index(:pined_posts, [:post_id, :community_id]))

    drop(table(:posts_topics))
    drop(table(:topics))
  end
end
