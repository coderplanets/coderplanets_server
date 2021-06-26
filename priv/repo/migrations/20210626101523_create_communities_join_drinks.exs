defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinDrinks do
  use Ecto.Migration

  def change do
    create table(:drink_documents) do
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end
  end
end
