defmodule GroupherServer.Repo.Migrations.CreatePinedRepos do
  use Ecto.Migration

  def change do
    create table(:pined_repos) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:pined_repos, [:repo_id, :community_id]))
  end
end
