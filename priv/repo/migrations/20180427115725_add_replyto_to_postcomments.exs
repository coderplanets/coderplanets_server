defmodule GroupherServer.Repo.Migrations.AddReplytoToPostcomments do
  use Ecto.Migration

  def change do
    alter table(:posts_comments) do
      # add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:reply_id, references(:posts_comments, on_delete: :delete_all))
    end
  end
end
