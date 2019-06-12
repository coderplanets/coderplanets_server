defmodule GroupherServer.Repo.Migrations.CreateMentionMails do
  use Ecto.Migration

  def change do
    create table(:mention_mails) do
      add(:source_type, :string)
      add(:source_id, :string)
      add(:source_title, :string)
      add(:source_preview, :string)
      add(:parent_type, :string)
      add(:parent_id, :string)
      add(:from_user_id, references(:users, on_delete: :nothing), null: false)
      add(:to_user_id, references(:users, on_delete: :nothing), null: false)

      add(:read, :boolean, default: false)

      timestamps()
    end

    create(index(:mention_mails, [:from_user_id]))
    create(index(:mention_mails, [:to_user_id]))
  end
end
