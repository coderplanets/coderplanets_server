defmodule GroupherServer.Repo.Migrations.AddReplyidToJobComments do
  use Ecto.Migration

  def change do
    alter table(:jobs_comments) do
      add(:reply_id, references(:jobs_comments, on_delete: :delete_all))
    end
  end
end
