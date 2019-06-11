defmodule GroupherServer.Repo.Migrations.AddOrignalCommunityToJob do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:origial_community_id, references(:communities, on_delete: :delete_all))
    end
  end
end
