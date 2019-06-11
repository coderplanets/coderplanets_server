defmodule GroupherServer.Repo.Migrations.CreateCommunitiesReposJoinTable do
  use Ecto.Migration

  def change do
    create table(:communities_repos) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_repos, [:community_id, :repo_id]))
  end
end
