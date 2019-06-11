defmodule GroupherServer.Repo.Migrations.CreateVideoComments do
  use Ecto.Migration

  def change do
    create table(:videos_comments) do
      add(:body, :text)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:video_id, references(:cms_videos, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:videos_comments, [:author_id]))
    create(index(:videos_comments, [:video_id]))
  end
end
