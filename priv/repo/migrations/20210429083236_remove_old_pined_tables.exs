defmodule GroupherServer.Repo.Migrations.RemoveOldPinedTables do
  use Ecto.Migration

  def change do
    drop(table(:pined_posts))
    drop(table(:pined_jobs))
    drop(table(:pined_repos))

    alter table(:pinned_articles) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end

    create(index(:pinned_articles, [:repo_id]))
    drop(unique_index(:pinned_articles, [:post_id, :job_id, :community_id]))
    create(unique_index(:pinned_articles, [:post_id, :community_id]))
    create(unique_index(:pinned_articles, [:job_id, :community_id]))
    create(unique_index(:pinned_articles, [:repo_id, :community_id]))
  end
end
