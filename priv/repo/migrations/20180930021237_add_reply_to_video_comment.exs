defmodule GroupherServer.Repo.Migrations.AddReplyToVideoComment do
  use Ecto.Migration

  def change do
    alter table(:videos_comments) do
      # add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:reply_id, references(:videos_comments, on_delete: :delete_all))
    end
  end
end
