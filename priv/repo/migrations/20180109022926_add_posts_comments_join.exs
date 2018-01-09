defmodule MastaniServer.Repo.Migrations.AddPostsCommentsJoin do
  use Ecto.Migration

  def change do
    create table(:cms_posts_comments) do
      add(:post_id, references(:cms_posts))
      add(:comment_id, references(:cms_comments))
    end
  end
end
