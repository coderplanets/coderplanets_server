defmodule MastaniServer.Repo.Migrations.DropOldCommentsStarsTable do
  use Ecto.Migration

  def change do
    drop(table("users_posts_stars"))
    drop(table("posts_comments"))
    drop(table("cms_comments"))
  end
end
