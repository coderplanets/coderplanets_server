defmodule GroupherServer.Repo.Migrations.CopyRightDefaultForJobs do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      remove(:copy_right)

      add(:copy_right, :string, default: "original")
    end
  end
end
