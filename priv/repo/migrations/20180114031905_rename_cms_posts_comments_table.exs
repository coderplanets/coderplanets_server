defmodule MastaniServer.Repo.Migrations.RenameCmsPostsCommentsTable do
  use Ecto.Migration

  def change do
    rename(table("cms_posts_comments"), to: table("posts_comments"))
  end
end
