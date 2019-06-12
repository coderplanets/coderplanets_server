defmodule GroupherServer.Repo.Migrations.AddUniqueIndexToPublishThrottle do
  use Ecto.Migration

  def change do
    drop(index(:publish_throttles, [:user_id]))
    create(unique_index(:publish_throttles, [:user_id]))
  end
end
