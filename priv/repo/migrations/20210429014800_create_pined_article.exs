defmodule GroupherServer.Repo.Migrations.CreatePinedArticle do
  use Ecto.Migration

  def change do
    create table(:pined_articles) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:pined_articles, [:post_id]))
    create(index(:pined_articles, [:job_id]))
    create(index(:pined_articles, [:community_id]))
    create(unique_index(:pined_articles, [:post_id, :job_id, :community_id]))
  end
end
