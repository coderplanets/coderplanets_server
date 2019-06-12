defmodule GroupherServer.Repo.Migrations.CreateVideoCommentsReply do
  use Ecto.Migration

  def change do
    create table(:videos_comments_replies) do
      add(:comment_id, references(:videos_comments, on_delete: :delete_all), null: false)
      add(:reply_id, references(:videos_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:videos_comments_replies, [:comment_id]))
    create(index(:videos_comments_replies, [:reply_id]))
  end
end
