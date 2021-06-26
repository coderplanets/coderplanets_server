defmodule GroupherServer.Repo.Migrations.CreateGuideDocument do
  use Ecto.Migration

  def change do
    create table(:guide_documents) do
      add(:radar_id, references(:cms_radars, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end
  end
end
