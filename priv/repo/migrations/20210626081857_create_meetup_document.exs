defmodule GroupherServer.Repo.Migrations.CreateMeetupDocument do
  use Ecto.Migration

  def change do
    create table(:meetup_documents) do
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all), null: false)
      add(:body, :text)
      add(:body_html, :text)
      add(:markdown, :text)
      add(:toc, :map)
    end
  end
end
