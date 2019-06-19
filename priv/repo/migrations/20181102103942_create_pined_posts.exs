defmodule GroupherServer.Repo.Migrations.CreatePinedPosts do
  use Ecto.Migration

  def change do
    create table(:pined_posts) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:topic_id, references(:topics, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:pined_posts, [:post_id, :community_id, :topic_id]))
  end
end
