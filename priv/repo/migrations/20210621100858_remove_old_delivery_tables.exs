defmodule GroupherServer.Repo.Migrations.RemoveOldDeliveryTables do
  use Ecto.Migration

  def change do
    drop(table(:old_mentions))
    drop(table(:old_notifications))
    drop(table(:sys_notifications))
  end
end
