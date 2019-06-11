defmodule GroupherServer.Repo.Migrations.CreateBillRecords do
  use Ecto.Migration

  def change do
    create table(:bill_records) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:hash_id, :string)
      add(:state, :string)

      add(:amount, :float)
      add(:payment_usage, :string)
      add(:payment_method, :string)

      timestamps()
    end

    create(index(:bill_records, [:user_id]))
    create(index(:bill_records, [:hash_id]))
  end
end
