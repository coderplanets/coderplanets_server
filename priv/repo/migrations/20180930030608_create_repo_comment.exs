defmodule GroupherServer.Repo.Migrations.CreateRepoComment do
  use Ecto.Migration

  def change do
    create table(:repos_comments) do
      add(:body, :text)
      add(:floor, :integer, default: 0)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      # add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:reply_id, references(:repos_comments, on_delete: :delete_all))

      timestamps()
    end

    create(index(:repos_comments, [:author_id]))
    create(index(:repos_comments, [:repo_id]))
  end
end
