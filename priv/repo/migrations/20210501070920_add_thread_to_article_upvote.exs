defmodule GroupherServer.Repo.Migrations.AddThreadToArticleUpvote do
  use Ecto.Migration

  def change do
    alter table(:article_upvotes) do
      add(:thread, :string)
    end
  end
end
