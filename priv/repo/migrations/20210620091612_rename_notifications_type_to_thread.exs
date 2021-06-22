defmodule GroupherServer.Repo.Migrations.RenameNotificationsTypeToThread do
  use Ecto.Migration

  def change do
    rename(table(:notifications), :type, to: :thread)
  end
end
