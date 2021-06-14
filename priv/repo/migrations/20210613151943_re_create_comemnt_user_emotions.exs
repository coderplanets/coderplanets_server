defmodule GroupherServer.Repo.Migrations.ReCreateComemntUserEmotions do
  use Ecto.Migration

  def change do
    create table(:comments_users_emotions) do
      add(:comment_id, references(:comments, on_delete: :delete_all), null: false)

      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:recived_user_id, references(:users, on_delete: :delete_all), null: false)

      add(:downvote, :boolean, default: false)
      add(:beer, :boolean, default: false)
      add(:heart, :boolean, default: false)
      add(:biceps, :boolean, default: false)
      add(:orz, :boolean, default: false)
      add(:confused, :boolean, default: false)
      add(:pill, :boolean, default: false)

      timestamps()
    end

    create(index(:comments_users_emotions, [:comment_id]))
    create(index(:comments_users_emotions, [:user_id]))
    create(index(:comments_users_emotions, [:recived_user_id]))
  end
end
