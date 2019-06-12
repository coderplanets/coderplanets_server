defmodule GroupherServer.Repo.Migrations.AddCommunitiesIndexToC11n do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      add(:sidebar_communities_index, :map)
    end
  end
end
