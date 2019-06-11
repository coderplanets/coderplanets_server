defmodule GroupherServer.Repo.Migrations.CleaupForJobs do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      remove(:location)
      remove(:copy_right)

      add(:copy_right, :string, default_value: "original")
    end
  end
end
