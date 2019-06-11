defmodule GroupherServer.Repo.Migrations.AddStarLanguageInfoToRepos do
  use Ecto.Migration

  def change do
    alter table(:cms_repos) do
      add(:star_count, :integer)
      remove(:primary_language)
      add(:primary_language, :map)
    end
  end
end
