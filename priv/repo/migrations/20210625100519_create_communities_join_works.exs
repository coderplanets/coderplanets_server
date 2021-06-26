defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinWorks do
  use Ecto.Migration

  def change do
    create table(:communities_join_works) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:works_id, references(:cms_works, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_works, [:community_id, :works_id]))
  end
end
