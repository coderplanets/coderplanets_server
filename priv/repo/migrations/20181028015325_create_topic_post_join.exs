defmodule GroupherServer.Repo.Migrations.CreateTopicPostJoin do
  use Ecto.Migration

  def change do
    create table(:posts_topics) do
      add(:topic_id, references(:topics, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
    end

    create(unique_index(:posts_topics, [:topic_id, :post_id]))
  end
end
