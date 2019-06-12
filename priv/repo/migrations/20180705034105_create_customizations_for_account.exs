defmodule GroupherServer.Repo.Migrations.CreateCustomizationsForAccount do
  use Ecto.Migration

  def change do
    create table(:customizations) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)

      add(:theme, :boolean)
      add(:community_chart, :boolean)
      add(:brainwash_free, :boolean)

      timestamps()
    end

    create(unique_index(:customizations, [:user_id]))
  end
end
