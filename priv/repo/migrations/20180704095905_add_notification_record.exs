defmodule GroupherServer.Repo.Migrations.AddNotificationRecord do
  use Ecto.Migration

  def change do
    alter table(:delivery_records) do
      add(:notifications_record, :map)
    end
  end
end
