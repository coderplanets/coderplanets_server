defmodule GroupherServer.Repo.Migrations.CreateAccountNotificationMails do
  use Ecto.Migration

  def change do
    create table(:notification_mails) do
      add(:action, :string)
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

    create(index(:notification_mails, [:from_user_id]))
    create(index(:notification_mails, [:to_user_id]))
  end
end
