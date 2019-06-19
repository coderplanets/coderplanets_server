defmodule GroupherServer.Repo.Migrations.CreateCommunityWiki do
  use Ecto.Migration

  def change do
    create table(:community_wikis) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:readme, :text)
      # this should be a embed schema
      add(:contributors, :map)
      add(:last_sync, :utc_datetime)

      timestamps()
    end

    create(index(:community_wikis, [:community_id]))
  end
end
