defmodule GroupherServer.Repo.Migrations.CreateCommentsUsersEmotions do
  use Ecto.Migration

  def change do
    create table(:articles_comments_users_emotions) do
      add(:article_comment_id, references(:articles_comments, on_delete: :delete_all), null: false)

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

    create(index(:articles_comments_users_emotions, [:article_comment_id]))
    create(index(:articles_comments_users_emotions, [:user_id]))
    create(index(:articles_comments_users_emotions, [:recived_user_id]))
  end
end
