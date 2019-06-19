defmodule GroupherServer.Repo.Migrations.AddUserToAccuntSysNotification do
  use Ecto.Migration

  def change do
    alter table(:sys_notification_mails) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
    end

    create(index(:sys_notification_mails, [:user_id]))
  end
end
