defmodule GroupherServer.Repo.Migrations.CreateWorksDocument do
  use Ecto.Migration

  def change do
    create table(:works_documents) do
      add(:works_id, references(:cms_works, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end
  end
end
