defmodule GroupherServer.Repo.Migrations.RmOldJobComments do
  use Ecto.Migration

  def change do
    drop(table(:jobs_comments_replies))
    drop(table(:jobs_comments_likes))
    drop(table(:jobs_comments_dislikes))
    drop(table(:jobs_comments))
  end
end
