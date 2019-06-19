defmodule GroupherServer.Repo.Migrations.CreatePurchaseForAccount do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)

      add(:theme, :boolean)
      add(:community_chart, :boolean)
      add(:brainwash_free, :boolean)

      timestamps()
    end

    create(unique_index(:purchases, [:user_id]))
  end
end
