defmodule GroupherServer.Repo.Migrations.CreateRepoCommentReply do
  use Ecto.Migration

  def change do
    create table(:repos_comments_replies) do
      add(:repo_comment_id, references(:repos_comments, on_delete: :delete_all), null: false)
      add(:reply_id, references(:repos_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:repos_comments_replies, [:repo_comment_id]))
    create(index(:repos_comments_replies, [:reply_id]))
  end
end
