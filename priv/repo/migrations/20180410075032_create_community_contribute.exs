defmodule GroupherServer.Repo.Migrations.CreateCommunityContribute do
  use Ecto.Migration

  def change do
    create table(:community_contributes) do
      add(:date, :date)
      add(:count, :integer)
      add(:community_id, references(:communities, on_delete: :delete_all, null: false))

      timestamps()
    end

    create(index(:community_contributes, [:community_id]))
  end
end
