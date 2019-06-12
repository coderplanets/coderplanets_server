defmodule GroupherServer.Repo.Migrations.AddFieldsForJobs do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:finance, :string)
      add(:scale, :string)
      add(:copy_right, :string)
    end
  end
end
