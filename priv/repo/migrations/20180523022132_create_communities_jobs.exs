defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJobs do
  use Ecto.Migration

  def change do
    create table(:communities_jobs) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_jobs, [:community_id, :job_id]))
  end
end
