defmodule GroupherServer.Repo.Migrations.RemoveArticleCommentInReports do
  use Ecto.Migration

  def up do
    alter(table(:abuse_reports),
      do:
        remove_if_exists(
          :article_comment_id,
          references(:articles_comments, on_delete: :delete_all)
        )
    )
  end

  def down do
    alter table(:abuse_reports) do
      add(:article_comment_id, references(:comments, on_delete: :delete_all))
    end
  end
end
