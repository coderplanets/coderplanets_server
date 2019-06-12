defmodule GroupherServer.Repo.Migrations.CreateVideosStars do
  use Ecto.Migration

  def change do
    create table(:videos_stars) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:videos_stars, [:user_id, :video_id]))
  end
end
