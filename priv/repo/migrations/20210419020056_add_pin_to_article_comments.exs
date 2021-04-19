defmodule GroupherServer.Repo.Migrations.AddPinToArticleComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_pined, :boolean, default: false)
    end

    create table(:articles_pined_comments) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))

      add(:article_comment_id, references(:articles_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:articles_pined_comments, [:post_id]))
    create(index(:articles_pined_comments, [:job_id]))
    create(index(:articles_pined_comments, [:article_comment_id]))

    create(unique_index(:articles_pined_comments, [:post_id, :job_id, :article_comment_id]))
  end
end
