defmodule GroupherServer.Repo.Migrations.CreateMentions do
  use Ecto.Migration

  def change do
    create table(:mentions) do
      add(:source_type, :string)
      add(:source_id, :string)
      add(:source_title, :string)
      add(:source_preview, :string)
      add(:parent_type, :string)
      add(:parent_id, :string)
      add(:from_user_id, references(:users, on_delete: :nothing), null: false)
      add(:to_user_id, references(:users, on_delete: :nothing), null: false)

      timestamps()
    end

    create(index(:mentions, [:from_user_id]))
    create(index(:mentions, [:to_user_id]))
  end
end
