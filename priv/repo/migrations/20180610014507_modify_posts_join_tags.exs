defmodule GroupherServer.Repo.Migrations.ModifyPostsJoinTags do
  use Ecto.Migration

  def change do
    drop(table(:posts_tags))

    create table(:posts_tags) do
      add(:tag_id, references(:tags), null: false)
      add(:post_id, references(:cms_posts), null: false)
    end

    create(unique_index(:posts_tags, [:tag_id, :post_id]))
  end
end
