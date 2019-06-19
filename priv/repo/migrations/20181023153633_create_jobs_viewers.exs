defmodule GroupherServer.Repo.Migrations.CreateJobsViewers do
  use Ecto.Migration

  def change do
    create table(:jobs_viewers) do
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:jobs_viewers, [:job_id, :user_id]))
  end
end
