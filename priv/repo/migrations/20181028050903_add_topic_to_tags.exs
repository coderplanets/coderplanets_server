defmodule GroupherServer.Repo.Migrations.AddTopicToTags do
  use Ecto.Migration

  def change do
    drop(unique_index(:tags, [:community_id, :thread, :title]))

    alter table(:tags) do
      add(:topic_id, references(:topics, on_delete: :delete_all))
    end

    create(unique_index(:tags, [:community_id, :thread, :topic_id, :title]))
  end
end
