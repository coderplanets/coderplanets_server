defmodule GroupherServer.Repo.Migrations.CreateCommunitiesSubscribers do
  use Ecto.Migration

  def change do
    create table(:communities_subscribers) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:communities_subscribers, [:user_id, :community_id]))
    create(index(:communities_subscribers, [:community_id]))
    create(index(:communities_subscribers, [:user_id]))
  end
end
