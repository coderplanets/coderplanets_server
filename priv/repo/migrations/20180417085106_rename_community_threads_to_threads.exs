defmodule GroupherServer.Repo.Migrations.RenameCommunityThreadsToThreads do
  use Ecto.Migration

  def change do
    rename(table("community_threads"), to: table("threads"))
  end
end
