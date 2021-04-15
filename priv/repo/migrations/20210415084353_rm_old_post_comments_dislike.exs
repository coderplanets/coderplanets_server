defmodule GroupherServer.Repo.Migrations.RmOldPostCommentsDislike do
  use Ecto.Migration

  def change do
    drop(table(:posts_comments_dislikes))
  end
end
