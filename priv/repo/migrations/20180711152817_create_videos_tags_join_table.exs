defmodule GroupherServer.Repo.Migrations.CreateVideosTagsJoinTable do
  use Ecto.Migration

  def change do
    create table(:videos_tags) do
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)
    end

    create(unique_index(:videos_tags, [:tag_id, :video_id]))
  end
end
