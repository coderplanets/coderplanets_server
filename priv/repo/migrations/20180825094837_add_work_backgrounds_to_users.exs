defmodule GroupherServer.Repo.Migrations.AddWorkBackgroundsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:work_backgrounds, :map)
    end
  end
end
