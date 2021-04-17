defmodule GroupherServer.Repo.Migrations.CreateArticleCommentParticipator do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:comment_participators, :map)
    end
  end
end
