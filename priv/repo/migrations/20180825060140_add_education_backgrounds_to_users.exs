defmodule GroupherServer.Repo.Migrations.AddEducationBackgroundsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:education_backgrounds, :map)
    end
  end
end
