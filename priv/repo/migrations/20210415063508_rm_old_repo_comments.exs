defmodule GroupherServer.Repo.Migrations.RmOldRepoComments do
  use Ecto.Migration

  def change do
    drop(table(:repos_comments_replies))
    drop(table(:repos_comments_likes))
    drop(table(:repos_comments_dislikes))
    drop(table(:repos_comments))
  end
end
