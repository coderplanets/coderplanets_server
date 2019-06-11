defmodule GroupherServer.Repo.Migrations.RemoveOldCommunityThreadsUniqueIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:community_threads, [:title]))
    create(unique_index(:threads, [:title]))
  end
end
