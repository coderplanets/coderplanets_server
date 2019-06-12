defmodule GroupherServer.Repo.Migrations.CreateVideosViewers do
  use Ecto.Migration

  def change do
    create table(:videos_viewers) do
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:videos_viewers, [:video_id, :user_id]))
  end
end
