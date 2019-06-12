defmodule GroupherServer.Repo.Migrations.AlterTagCommunity do
  use Ecto.Migration

  def change do
    drop(unique_index(:tags, [:community, :part, :title]))

    alter table(:tags) do
      remove(:community)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
    end

    create(unique_index(:tags, [:community_id, :part, :title]))
    create(index(:tags, [:community_id]))
  end
end
