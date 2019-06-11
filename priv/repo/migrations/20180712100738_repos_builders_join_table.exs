defmodule GroupherServer.Repo.Migrations.ReposBuildersJoinTable do
  use Ecto.Migration

  def change do
    create table(:repos_builders) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:builder_id, references(:cms_repo_builders, on_delete: :delete_all), null: false)
    end

    create(index(:repos_builders, [:repo_id]))
  end
end
