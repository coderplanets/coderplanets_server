defmodule GroupherServer.Repo.Migrations.RenameRepoLastFetch do
  use Ecto.Migration

  def change do
    rename(table(:cms_repos), :last_fetch_time, to: :last_sync)
  end
end
