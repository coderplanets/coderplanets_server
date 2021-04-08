defmodule GroupherServer.Repo.Migrations.CreaetArticleComments do
  use Ecto.Migration

  def change do
    create table(:articles_comments) do
      add(:body_html, :text)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))

      timestamps()
    end

    create(index(:articles_comments, [:author_id]))
    create(index(:articles_comments, [:post_id]))
    create(index(:articles_comments, [:job_id]))

    # create table(:repos_comments_replies) do
    #   add(:repo_comment_id, references(:repos_comments, on_delete: :delete_all), null: false)
    #   add(:reply_id, references(:repos_comments, on_delete: :delete_all), null: false)

    #   timestamps()
    # end

    # create(index(:repos_comments_replies, [:repo_comment_id]))
    # create(index(:repos_comments_replies, [:reply_id]))
  end
end
