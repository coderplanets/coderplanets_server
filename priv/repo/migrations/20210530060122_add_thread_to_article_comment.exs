defmodule GroupherServer.Repo.Migrations.AddThreadToArticleComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:thread, :string)
    end
  end
end
