defmodule GroupherServer.Repo.Migrations.AddCommunitiesTimestamp do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      timestamps()
    end
  end
end
