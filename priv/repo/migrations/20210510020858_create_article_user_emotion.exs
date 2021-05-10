defmodule GroupherServer.Repo.Migrations.CreateArticleUserEmotion do
  use Ecto.Migration

  def change do
    create table(:articles_users_emotions) do
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))

      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:recived_user_id, references(:users, on_delete: :delete_all), null: false)

      add(:upvote, :boolean, default: false)
      add(:downvote, :boolean, default: false)
      add(:beer, :boolean, default: false)
      add(:heart, :boolean, default: false)
      add(:biceps, :boolean, default: false)
      add(:orz, :boolean, default: false)
      add(:confused, :boolean, default: false)
      add(:pill, :boolean, default: false)
      add(:popcorn, :boolean, default: false)

      timestamps()
    end
  end
end
