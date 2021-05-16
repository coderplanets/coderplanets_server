defmodule GroupherServer.Repo.Migrations.RenameArticlesPinedComments do
  use Ecto.Migration

  def change do
    rename(table("articles_pined_comments"), to: table("articles_pinned_comments"))
  end
end
