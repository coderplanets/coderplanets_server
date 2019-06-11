defmodule GroupherServer.Repo.Migrations.CreateJobsComments do
  use Ecto.Migration

  def change do
    create table(:jobs_comments) do
      add(:body, :string)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
      add(:floor, :integer, default: 0)

      timestamps()
    end

    create(index(:jobs_comments, [:author_id]))
    create(index(:jobs_comments, [:job_id]))
    create(index(:jobs_comments, [:floor]))
  end
end
