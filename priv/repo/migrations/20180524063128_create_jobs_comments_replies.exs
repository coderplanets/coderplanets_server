defmodule GroupherServer.Repo.Migrations.CreateJobsCommentsReplies do
  use Ecto.Migration

  def change do
    create table(:jobs_comments_replies) do
      add(:job_comment_id, references(:jobs_comments, on_delete: :delete_all), null: false)
      add(:reply_id, references(:jobs_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:jobs_comments_replies, [:job_comment_id]))
    create(index(:jobs_comments_replies, [:reply_id]))
  end
end
