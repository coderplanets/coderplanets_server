defmodule GroupherServer.Repo.Migrations.CreateCmsVideos do
  use Ecto.Migration

  def change do
    create table(:cms_videos) do
      add(:title, :string)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
      add(:poster, :string)
      add(:desc, :string)
      add(:duration, :string)
      add(:duration_sec, :integer)
      add(:source, :string)
      add(:link, :string)
      add(:original_author, :string)
      add(:original_author_link, :string)
      add(:publish_at, :utc_datetime)

      add(:views, :integer, default: 0)
      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)

      timestamps()
    end

    create(index(:cms_videos, [:author_id]))
  end
end
