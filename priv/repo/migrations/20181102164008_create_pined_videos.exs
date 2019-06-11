defmodule GroupherServer.Repo.Migrations.CreatePinedVideos do
  use Ecto.Migration

  def change do
    create table(:pined_videos) do
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:pined_videos, [:video_id, :community_id]))
  end
end
