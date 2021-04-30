defmodule GroupherServer.Repo.Migrations.CreateCollectForArticle do
  use Ecto.Migration

  def change do
    create table(:article_collects) do
      add(:thread, :string)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))

      timestamps()
    end

    create(index(:article_collects, [:user_id]))
    create(index(:article_collects, [:post_id]))
    create(index(:article_collects, [:job_id]))
    create(index(:article_collects, [:repo_id]))

    create(unique_index(:article_collects, [:user_id, :post_id]))
    create(unique_index(:article_collects, [:user_id, :job_id]))
    create(unique_index(:article_collects, [:user_id, :repo_id]))
  end
end
