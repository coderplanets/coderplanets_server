defmodule GroupherServer.Repo.Migrations.RenameCommunityFlagConecpt do
  use Ecto.Migration

  def change do
    drop(table(:posts_communities_flags))
    drop(table(:jobs_communities_flags))
    drop(table(:repos_communities_flags))
  end
end
