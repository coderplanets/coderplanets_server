defmodule GroupherServer.Repo.Migrations.RemoveOldAccountMails do
  use Ecto.Migration

  def change do
    drop(table(:mention_mails))
    drop(table(:notification_mails))
    drop(table(:sys_notification_mails))
  end
end
