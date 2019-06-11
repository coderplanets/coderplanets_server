defmodule GroupherServer.Repo.Migrations.CreateReposCommunitiesFlags do
  use Ecto.Migration

  def change do
    create table(:repos_communities_flags) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:repos_communities_flags, [:repo_id, :community_id]))
  end
end
