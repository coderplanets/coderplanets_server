defmodule GroupherServer.Repo.Migrations.AddUniqueIndexToTags do
  use Ecto.Migration

  def change do
    create(unique_index(:tags, [:community_id, :thread, :title]))
  end
end
