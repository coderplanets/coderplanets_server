defmodule GroupherServer.Repo.Migrations.AddEmotionsToCmsJobs do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:emotions, :map)
    end
  end
end
