defmodule GroupherServer.Repo.Migrations.CreateNewNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      # article or comment
      add(:type, :string)
      add(:article_id, :id)
      add(:title, :string)
      # optional comment id
      add(:comment_id, :id)
      #
      add(:action, :string)
      add(:from_users, :map)

      add(:read, :boolean, default: false)

      timestamps()
    end

    create(index(:notifications, [:user_id]))
  end
end
