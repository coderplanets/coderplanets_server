defmodule GroupherServer.Repo.Migrations.AddDrinkCommunityJoinTable do
  use Ecto.Migration

  def change do
    create table(:communities_join_drinks) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:drink_id, references(:cms_drinks, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_drinks, [:community_id, :drink_id]))
  end
end
