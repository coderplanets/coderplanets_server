defmodule GroupherServer.Repo.Migrations.AlterRepos do
  use Ecto.Migration

  def change do
    alter table(:cms_repos) do
      add(:title, :string)
      add(:owner_name, :string)
      add(:owner_url, :string)
      add(:repo_url, :string)

      add(:homepage_url, :string)

      add(:issuesCount, :integer)
      add(:prsCount, :integer)
      add(:forkCount, :integer)
      add(:watchCount, :integer)

      add(:primary_language, :string)
      add(:license, :string)
      add(:releaseTag, :string)

      add(:contributors, :map)

      remove(:repo_name)
      remove(:repo_link)

      remove(:language)
      remove(:producer)
      remove(:producer_link)

      remove(:repo_star_count)
      remove(:repo_fork_count)
      remove(:repo_watch_count)
    end
  end
end
