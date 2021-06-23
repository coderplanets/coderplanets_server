defmodule GroupherServer.Repo.Migrations.AddFromUsersCountToNotification do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add(:from_users_count, :integer)
    end
  end
end
