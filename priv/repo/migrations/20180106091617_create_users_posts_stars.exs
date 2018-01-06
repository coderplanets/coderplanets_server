defmodule MastaniServer.Repo.Migrations.CreateUsersPostsStars do
  use Ecto.Migration

  def change do
    create table(:users_posts_stars) do
      add(:user_id, references(:users))
      add(:post_id, references(:cms_posts))
    end
  end
end
