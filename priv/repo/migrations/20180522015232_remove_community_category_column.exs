defmodule GroupherServer.Repo.Migrations.RemoveCommunityCategoryColumn do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      remove(:category)
    end
  end
end
