defmodule GroupherServer.Repo.Migrations.CreateCollectFolder do
  use Ecto.Migration

  def change do
    create table(:collect_folders) do
      add(:user_id, references(:users, on_delete: :delete_all, null: false))

      add(:title, :string)
      add(:desc, :string)
      add(:total_count, :integer, default: 0)
      add(:index, :integer)
      add(:private, :boolean, default: false)

      add(:collects, :map)
      add(:last_updated, :utc_datetime)

      timestamps()
    end

    create(unique_index(:collect_folders, [:user_id, :title]))
  end
end
