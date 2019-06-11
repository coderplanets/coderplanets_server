defmodule GroupherServer.Repo.Migrations.CreateReposTagsJoinTable do
  use Ecto.Migration

  def change do
    create table(:repos_tags) do
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
    end

    create(unique_index(:repos_tags, [:tag_id, :repo_id]))
  end
end
