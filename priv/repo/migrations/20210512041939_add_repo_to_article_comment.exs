defmodule GroupherServer.Repo.Migrations.AddRepoToArticleComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end

    create(index(:articles_comments, [:repo_id]))
  end
end
