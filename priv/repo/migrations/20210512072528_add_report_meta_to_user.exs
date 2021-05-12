defmodule GroupherServer.Repo.Migrations.AddReportMetaToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_reported, :boolean, default: false)
      add(:meta, :map)
    end
  end
end
