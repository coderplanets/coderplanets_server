defmodule GroupherServer.Repo.Migrations.CreaetArticleDocuments do
  use Ecto.Migration

  def change do
    create table(:article_documents) do
      add(:thread, :string)
      add(:article_id, :id)
      add(:title, :string)
      add(:body, :text)
      add(:body_html, :text)

      timestamps()
    end
  end
end
