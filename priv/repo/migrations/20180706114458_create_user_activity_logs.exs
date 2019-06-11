defmodule GroupherServer.Repo.Migrations.CreateUserActivityLogs do
  use Ecto.Migration

  def change do
    create table(:user_activity_logs) do
      add(:source_id, :string)
      add(:source_title, :string)
      add(:source_type, :string)
      add(:user_id, references(:users, on_delete: :nothing), null: false)

      timestamps()
    end

    create(index(:user_activity_logs, [:user_id]))
  end
end
