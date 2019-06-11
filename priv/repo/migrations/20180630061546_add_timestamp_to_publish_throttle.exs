defmodule GroupherServer.Repo.Migrations.AddTimestampToPublishThrottle do
  use Ecto.Migration

  def change do
    alter table(:publish_throttles) do
      timestamps()
    end
  end
end
