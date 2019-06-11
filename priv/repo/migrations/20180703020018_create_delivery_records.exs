defmodule GroupherServer.Repo.Migrations.CreateDeliveryRecords do
  use Ecto.Migration

  def change do
    create table(:delivery_records) do
      add(:mentions_record, :map)
      add(:user_id, references(:users, on_delete: :nothing), null: false)

      timestamps()
    end

    create(unique_index(:delivery_records, [:user_id]))
  end
end
