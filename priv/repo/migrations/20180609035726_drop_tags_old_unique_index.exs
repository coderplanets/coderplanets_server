defmodule GroupherServer.Repo.Migrations.DropTagsOldUniqueIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:tags, [:community_id, :part, :title]))
  end
end
