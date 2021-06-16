defmodule GroupherServer.Repo.Migrations.BackOldMentionAndNotifications do
  use Ecto.Migration

  def change do
    rename(table("mentions"), to: table("old_mentions"))
    rename(table("notifications"), to: table("old_notifications"))
  end
end
