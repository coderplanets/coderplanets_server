defmodule GroupherServer.Repo.Migrations.AddOrignalCommunityToVideo do
  use Ecto.Migration

  def change do
    alter table(:cms_videos) do
      add(:origial_community_id, references(:communities, on_delete: :delete_all))
    end
  end
end
