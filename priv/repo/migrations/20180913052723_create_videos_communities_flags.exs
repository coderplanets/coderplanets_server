defmodule GroupherServer.Repo.Migrations.CreateVideosCommunitiesFlags do
  use Ecto.Migration

  def change do
    create table(:videos_communities_flags) do
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:videos_communities_flags, [:video_id, :community_id]))
  end
end
