defmodule GroupherServer.Repo.Migrations.RenameReposFiels do
  use Ecto.Migration

  def change do
    rename(table(:cms_repos), :issuesCount, to: :issues_count)
    rename(table(:cms_repos), :prsCount, to: :prs_count)
    rename(table(:cms_repos), :forkCount, to: :fork_count)
    rename(table(:cms_repos), :watchCount, to: :watch_count)

    rename(table(:cms_repos), :releaseTag, to: :release_tag)
  end
end
