defmodule GroupherServer.Repo.Migrations.RemoveOldDeliveryRecords do
  use Ecto.Migration

  def change do
    drop(table(:delivery_records))
  end
end
