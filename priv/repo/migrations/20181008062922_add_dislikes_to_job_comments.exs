defmodule GroupherServer.Repo.Migrations.AddDislikesToJobComments do
  use Ecto.Migration

  def change do
    create table(:jobs_comments_dislikes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:job_comment_id, references(:jobs_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:jobs_comments_dislikes, [:user_id, :job_comment_id]))
  end
end
