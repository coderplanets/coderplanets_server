defmodule GroupherServer.Repo.Migrations.AddReplyToIdToArticleComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:reply_to_id, references(:articles_comments, on_delete: :delete_all))
    end
  end
end
