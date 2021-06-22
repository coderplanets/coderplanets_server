defmodule GroupherServer.Repo.Migrations.BackOldMentionAndNotifications do
  use Ecto.Migration

  def change do
    drop(index(:mentions, [:from_user_id]))
    drop(index(:mentions, [:to_user_id]))

    rename(table("mentions"), to: table("old_mentions"))
    rename(table("notifications"), to: table("old_notifications"))
  end
end
