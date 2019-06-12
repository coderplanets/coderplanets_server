defmodule GroupherServer.Repo.Migrations.CreateAccountSysNotificationMail do
  use Ecto.Migration

  def change do
    create table(:sys_notification_mails) do
      add(:source_type, :string)
      add(:source_id, :string)
      add(:source_title, :string)
      add(:source_preview, :string)

      add(:read, :boolean, default: false)

      timestamps()
    end
  end
end
