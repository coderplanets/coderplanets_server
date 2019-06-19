defmodule GroupherServer.Repo.Migrations.AlterVideoRepoDescToText do
  use Ecto.Migration

  def change do
    alter table(:cms_videos) do
      remove(:desc)
      add(:desc, :text)
    end
  end
end
