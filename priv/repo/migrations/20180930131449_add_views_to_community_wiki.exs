defmodule GroupherServer.Repo.Migrations.AddViewsToCommunityWiki do
  use Ecto.Migration

  def change do
    alter table(:community_wikis) do
      add(:views, :integer, default: 0)
    end
  end
end
