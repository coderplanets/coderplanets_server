defmodule GroupherServer.Repo.Migrations.AddOrignalCommunityToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:origial_community_id, references(:communities, on_delete: :delete_all))
    end
  end
end
