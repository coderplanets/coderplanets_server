defmodule GroupherServer.Repo.Migrations.AddCommentIdToReports do
  use Ecto.Migration

  def change do
    alter table(:abuse_reports) do
      add(:comment_id, references(:comments, on_delete: :delete_all))
    end
  end
end
