defmodule GroupherServer.Repo.Migrations.CreateUserAchievements do
  use Ecto.Migration

  def change do
    create table(:user_achievements) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:contents_stared_count, :integer, default: 0)
      add(:contents_favorited_count, :integer, default: 0)
      add(:contents_watched_count, :integer, default: 0)
      add(:followers_count, :integer, default: 0)
      add(:reputation, :integer, default: 0)

      timestamps()
    end

    create(index(:user_achievements, [:user_id]))
  end
end
