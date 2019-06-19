defmodule GroupherServer.Repo.Migrations.CreateJobsTagsJoinTable do
  use Ecto.Migration

  def change do
    create table(:jobs_tags) do
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
    end

    create(unique_index(:jobs_tags, [:tag_id, :job_id]))
  end
end
