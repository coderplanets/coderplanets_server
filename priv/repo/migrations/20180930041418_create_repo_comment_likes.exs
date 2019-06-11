defmodule GroupherServer.Repo.Migrations.CreateRepoCommentLikes do
  use Ecto.Migration

  def change do
    create table(:repos_comments_likes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:repo_comment_id, references(:repos_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:repos_comments_likes, [:user_id, :repo_comment_id]))
  end
end
