defmodule GroupherServer.Repo.Migrations.RenameCommentParticipators do
  use Ecto.Migration

  def change do
    rename(table(:cms_posts), :comment_participators, to: :article_comments_participators)
  end
end
