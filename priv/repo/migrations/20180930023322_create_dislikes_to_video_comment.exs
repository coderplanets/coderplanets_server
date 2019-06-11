defmodule GroupherServer.Repo.Migrations.CreateDislikesToVideoComment do
  use Ecto.Migration

  def change do
    create table(:videos_comments_dislikes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:video_comment_id, references(:videos_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:videos_comments_dislikes, [:user_id, :video_comment_id]))
  end
end
