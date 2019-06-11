defmodule GroupherServer.Repo.Migrations.CreateReposViewers do
  use Ecto.Migration

  def change do
    create table(:repos_viewers) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:repos_viewers, [:repo_id, :user_id]))
  end
end
