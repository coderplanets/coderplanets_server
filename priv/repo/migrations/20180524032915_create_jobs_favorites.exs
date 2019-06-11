defmodule GroupherServer.Repo.Migrations.CreateJobsFavorites do
  use Ecto.Migration

  def change do
    create table(:jobs_favorites) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:job_id, references(:cms_jobs, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:jobs_favorites, [:user_id, :job_id]))
  end
end
