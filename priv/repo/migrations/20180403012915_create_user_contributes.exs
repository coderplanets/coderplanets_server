defmodule GroupherServer.Repo.Migrations.CreateUserContribute do
  use Ecto.Migration

  def change do
    create table(:user_contributes) do
      add(:date, :date)
      add(:count, :integer)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:user_contributes, [:user_id]))
  end
end
