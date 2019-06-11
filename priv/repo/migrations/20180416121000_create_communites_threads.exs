defmodule GroupherServer.Repo.Migrations.CreateCommunitesThreads do
  use Ecto.Migration

  def change do
    create table(:communities_threads) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:thread_id, references(:community_threads, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:communities_threads, [:community_id, :thread_id]))
  end
end
