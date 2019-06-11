defmodule GroupherServer.Repo.Migrations.CreateJobsCommunitiesFlags do
  use Ecto.Migration

  def change do
    create table(:jobs_communities_flags) do
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:jobs_communities_flags, [:job_id, :community_id]))
  end
end
