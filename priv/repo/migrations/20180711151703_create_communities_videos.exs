defmodule GroupherServer.Repo.Migrations.CreateCommunitiesVideos do
  use Ecto.Migration

  def change do
    create table(:communities_videos) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_videos, [:community_id, :video_id]))
  end
end
