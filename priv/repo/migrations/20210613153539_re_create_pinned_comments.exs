defmodule GroupherServer.Repo.Migrations.ReCreatePinnedComments do
  use Ecto.Migration

  def change do
    create table(:pinned_comments) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))

      add(:comment_id, references(:comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:pinned_comments, [:post_id]))
    create(index(:pinned_comments, [:job_id]))
    create(index(:pinned_comments, [:repo_id]))
    create(index(:pinned_comments, [:blog_id]))
    create(index(:pinned_comments, [:comment_id]))

    create(unique_index(:pinned_comments, [:post_id, :job_id, :repo_id, :blog_id, :comment_id]))
  end
end
