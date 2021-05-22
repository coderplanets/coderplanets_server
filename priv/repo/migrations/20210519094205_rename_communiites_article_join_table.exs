defmodule GroupherServer.Repo.Migrations.RenameCommuniitesArticleJoinTable do
  use Ecto.Migration

  def change do
    rename(table(:communities_posts), to: table(:communities_join_posts))
    rename(table(:communities_jobs), to: table(:communities_join_jobs))
    rename(table(:communities_repos), to: table(:communities_join_repos))

    # drop(unique_index(:communities_posts, [:community_id, :post_id]))
    # drop(unique_index(:communities_posts, [:community_id, :post_id]))
    # drop(unique_index(:communities_posts, [:community_id, :post_id]))

    create(unique_index(:communities_join_posts, [:community_id, :post_id]))
    create(unique_index(:communities_join_jobs, [:community_id, :job_id]))
    create(unique_index(:communities_join_repos, [:community_id, :repo_id]))
  end
end
