defmodule GroupherServer.Repo.Migrations.CreatePostsCommunitiesFlags do
  use Ecto.Migration

  def change do
    create table(:posts_communities_flags) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)
      add(:refined, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:posts_communities_flags, [:post_id, :community_id]))
  end
end
