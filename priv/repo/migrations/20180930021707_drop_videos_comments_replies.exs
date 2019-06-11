defmodule GroupherServer.Repo.Migrations.DropVideosCommentsReplies do
  use Ecto.Migration

  def change do
    drop(table(:videos_comments_replies))
  end
end
