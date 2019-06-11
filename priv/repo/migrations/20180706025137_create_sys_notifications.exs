defmodule GroupherServer.Repo.Migrations.CreateSysNotifications do
  use Ecto.Migration

  def change do
    create table(:sys_notifications) do
      add(:source_id, :string)
      add(:source_type, :string)
      add(:source_title, :string)
      add(:source_preview, :string)

      timestamps()
    end
  end
end
