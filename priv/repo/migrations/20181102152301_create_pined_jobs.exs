defmodule GroupherServer.Repo.Migrations.CreatePinedJobs do
  use Ecto.Migration

  def change do
    create table(:pined_jobs) do
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:pined_jobs, [:job_id, :community_id]))
  end
end
