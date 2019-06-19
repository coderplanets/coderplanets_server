defmodule GroupherServer.Repo.Migrations.CreateCommunityCheatsheets do
  use Ecto.Migration

  def change do
    create table(:community_cheatsheets) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:readme, :text)
      # this should be a embed schema
      add(:contributors, :map)
      add(:last_sync, :utc_datetime)
      add(:views, :integer, default: 0)

      timestamps()
    end

    create(index(:community_cheatsheets, [:community_id]))
  end
end
