defmodule GroupherServer.Repo.Migrations.RenameAchievementFields do
  use Ecto.Migration

  def change do
    rename(table(:user_achievements), :contents_stared_count, to: :articles_upvotes_count)
    rename(table(:user_achievements), :contents_favorited_count, to: :articles_collects_count)
  end
end
