defmodule GroupherServer.Repo.Migrations.AddThumbnilToVideos do
  use Ecto.Migration

  def change do
    alter table(:cms_videos) do
      add(:thumbnil, :string)
    end
  end
end
