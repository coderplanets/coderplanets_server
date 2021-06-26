defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinGuides do
  use Ecto.Migration

  def change do
    create table(:communities_join_guides) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:guide_id, references(:cms_guides, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_guides, [:community_id, :guide_id]))
  end
end
