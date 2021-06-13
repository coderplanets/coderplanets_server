defmodule GroupherServer.Repo.Migrations.RenamePinnedArticleComemnts do
  use Ecto.Migration

  def change do
    rename(table(:articles_pinned_comments), to: table(:pinned_comments))
  end
end
