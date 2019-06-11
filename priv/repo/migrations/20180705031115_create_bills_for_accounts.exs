defmodule GroupherServer.Repo.Migrations.CreateBillsForAccounts do
  use Ecto.Migration

  def change do
    create table(:bills) do
      add(:from_user_id, references(:users, on_delete: :nothing), null: false)
      add(:to_user_id, references(:users, on_delete: :nothing), null: false)

      add(:source_type, :string)
      add(:source_id, :string)
      add(:source_title, :string)
      add(:price, :integer)

      timestamps()
    end

    create(index(:bills, [:from_user_id]))
    create(index(:bills, [:to_user_id]))
  end
end
