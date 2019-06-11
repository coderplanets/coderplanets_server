defmodule GroupherServer.Repo.Migrations.AddSysRecordToDeliveryRecords do
  use Ecto.Migration

  def change do
    alter table(:delivery_records) do
      add(:sys_notifications_record, :map)
    end
  end
end
