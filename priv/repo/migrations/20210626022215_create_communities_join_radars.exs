defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinRadars do
  use Ecto.Migration

  def change do
    create table(:communities_join_radars) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:radar_id, references(:cms_radars, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_radars, [:community_id, :radar_id]))
  end
end
