defmodule GroupherServer.Repo.Migrations.CreateUsersFollowers do
  use Ecto.Migration

  def change do
    create table(:users_followers) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:follower_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:users_followers, [:user_id, :follower_id]))
  end
end
