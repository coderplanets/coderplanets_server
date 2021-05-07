defmodule GroupherServer.Repo.Migrations.RemoveViewerTables do
  use Ecto.Migration

  def change do
    drop(table(:posts_viewers))
    drop(table(:jobs_viewers))
    drop(table(:repos_viewers))
  end
end
