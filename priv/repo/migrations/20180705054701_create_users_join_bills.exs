defmodule GroupherServer.Repo.Migrations.CreateUsersJoinBills do
  use Ecto.Migration

  def change do
    create table(:users_bills) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:bill_id, references(:bills, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:users_bills, [:user_id]))
    create(index(:users_bills, [:bill_id]))
  end
end
