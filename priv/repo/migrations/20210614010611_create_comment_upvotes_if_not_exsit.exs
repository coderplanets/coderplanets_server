defmodule GroupherServer.Repo.Migrations.CreateCommentUpvotesIfNotExsit do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:comments_upvotes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:comment_id, references(:comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create_if_not_exists(unique_index(:comments_upvotes, [:user_id, :comment_id]))
  end
end
