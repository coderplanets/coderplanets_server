defmodule GroupherServer.Repo.Migrations.CreateRepoCommentDislikes do
  use Ecto.Migration

  def change do
    create table(:repos_comments_dislikes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:repo_comment_id, references(:repos_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:repos_comments_dislikes, [:user_id, :repo_comment_id]))
  end
end
