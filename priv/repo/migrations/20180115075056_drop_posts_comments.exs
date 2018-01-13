defmodule MastaniServer.Repo.Migrations.DropPostsComments do
  use Ecto.Migration

  def change do
    drop(table("posts_comments"))
  end
end
