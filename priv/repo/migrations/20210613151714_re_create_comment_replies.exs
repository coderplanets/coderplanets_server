defmodule GroupherServer.Repo.Migrations.ReCreateCommentReplies do
  use Ecto.Migration

  def change do
    create table(:comments_replies) do
      add(:comment_id, references(:comments, on_delete: :delete_all), null: false)

      add(:reply_to_id, references(:comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:comments_replies, [:comment_id]))
    create(index(:comments_replies, [:reply_to_id]))
  end
end
